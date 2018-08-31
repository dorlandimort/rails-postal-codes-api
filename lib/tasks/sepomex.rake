require 'rake'
require 'net/http'
require 'uri'
require 'zip'
require 'csv'
namespace :sepomex do
  task :update => :environment do
    uri = URI.parse('http://www.correosdemexico.gob.mx/lservicios/servicios/CodigoPostal_Exportar.aspx')

    params = {
        '__VIEWSTATE' => '/wEPDwUKMTIxMDU0NDIwMA9kFgICAQ9kFgICAQ9kFgYCAw8PFgIeBFRleHQFOsOabHRpbWEgQWN0dWFsaXphY2nDs24gZGUgSW5mb3JtYWNpw7NuOiBPY3R1YnJlIDEyIGRlIDIwMTVkZAIHDxAPFgYeDURhdGFUZXh0RmllbGQFA0Vkbx4ORGF0YVZhbHVlRmllbGQFBUlkRWRvHgtfIURhdGFCb3VuZGdkEBUhIy0tLS0tLS0tLS0gVCAgbyAgZCAgbyAgcyAtLS0tLS0tLS0tDkFndWFzY2FsaWVudGVzD0JhamEgQ2FsaWZvcm5pYRNCYWphIENhbGlmb3JuaWEgU3VyCENhbXBlY2hlFENvYWh1aWxhIGRlIFphcmFnb3phBkNvbGltYQdDaGlhcGFzCUNoaWh1YWh1YRBEaXN0cml0byBGZWRlcmFsB0R1cmFuZ28KR3VhbmFqdWF0bwhHdWVycmVybwdIaWRhbGdvB0phbGlzY28HTcOpeGljbxRNaWNob2Fjw6FuIGRlIE9jYW1wbwdNb3JlbG9zB05heWFyaXQLTnVldm8gTGXDs24GT2F4YWNhBlB1ZWJsYQpRdWVyw6l0YXJvDFF1aW50YW5hIFJvbxBTYW4gTHVpcyBQb3Rvc8OtB1NpbmFsb2EGU29ub3JhB1RhYmFzY28KVGFtYXVsaXBhcwhUbGF4Y2FsYR9WZXJhY3J1eiBkZSBJZ25hY2lvIGRlIGxhIExsYXZlCFl1Y2F0w6FuCVphY2F0ZWNhcxUhAjAwAjAxAjAyAjAzAjA0AjA1AjA2AjA3AjA4AjA5AjEwAjExAjEyAjEzAjE0AjE1AjE2AjE3AjE4AjE5AjIwAjIxAjIyAjIzAjI0AjI1AjI2AjI3AjI4AjI5AjMwAjMxAjMyFCsDIWdnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2RkAh0PPCsACwBkGAEFHl9fQ29udHJvbHNSZXF1aXJlUG9zdEJhY2tLZXlfXxYBBQtidG5EZXNjYXJnYW7mKf2QWdV7ACF9fcRwj17tjpW4',
        '__EVENTVALIDATION' => '/wEWKAKgn7qiAQLG/OLvBgLWk4iCCgLWk4SCCgLWk4CCCgLWk7yCCgLWk7iCCgLWk7SCCgLWk7CCCgLWk6yCCgLWk+iBCgLWk+SBCgLJk4iCCgLJk4SCCgLJk4CCCgLJk7yCCgLJk7iCCgLJk7SCCgLJk7CCCgLJk6yCCgLJk+iBCgLJk+SBCgLIk4iCCgLIk4SCCgLIk4CCCgLIk7yCCgLIk7iCCgLIk7SCCgLIk7CCCgLIk6yCCgLIk+iBCgLIk+SBCgLLk4iCCgLLk4SCCgLLk4CCCgLL+uTWBALa4Za4AgK+qOyRAQLI56b6CwL1/KjtBePsl9sOAa2kuhQy2NGiYZah6Oiv',
        'cboEdo' => '00',
        'rblTipo' => 'txt',
        'btnDescarga.x' => '44',
        'btnDescarga.y' => '10'
    }
    puts 'Downloading postal codes from SEPOMEX'
    response_post = Net::HTTP.post_form(uri, params)

    puts 'Writing Zip'
    File.open('latest.zip', 'w', encoding: 'ASCII-8BIT') do |file|
      file.write response_post.body
    end

    puts 'Extracting Zip'
    Zip::File.open('latest.zip') do |zip_file|
      zip_file.extract('CPdescarga.txt', 'latest.csv') { true }
    end

    cmd = 'tail -n +2 latest.csv > latest_temp.csv'
    if system(cmd)
      ActiveRecord::Base.logger = nil
      puts "Inserting records"
      CSV.foreach('latest_temp.csv', encoding: 'ISO-8859-1:UTF-8', col_sep: '|', quote_char: '%', headers: true).each do |row|
        arg = {
            code: row['d_codigo'],
            colony: row['d_asenta'],
            municipality: row['D_mnpio'],
            state: row['d_estado']
        }
        PostalCode.find_or_create_by(arg)
      end
      puts "Done inserting records"
    else
      puts "fallo en comando"
    end
    puts ''
    puts 'Removing TempFiles'
    File.delete('latest.csv')
    File.delete('latest_temp.csv')
    File.delete('latest.zip')
  end
end