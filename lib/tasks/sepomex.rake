require 'rake'
require 'net/http'
require 'uri'
require 'zip'
require 'csv'
namespace :sepomex do
  task :update => :environment do
    uri = URI.parse('https://www.correosdemexico.gob.mx/SSLServicios/ConsultaCP/CodigoPostal_Exportar.aspx')

    params = {
        '__VIEWSTATE' => '/wEPDwUINzcwOTQyOTgPZBYCAgEPZBYCAgEPZBYGAgMPDxYCHgRUZXh0BTzDmmx0aW1hIEFjdHVhbGl6YWNpw7NuIGRlIEluZm9ybWFjacOzbjogTm92aWVtYnJlIDI4IGRlIDIwMTlkZAIHDxAPFgYeDURhdGFUZXh0RmllbGQFA0Vkbx4ORGF0YVZhbHVlRmllbGQFBUlkRWRvHgtfIURhdGFCb3VuZGdkEBUhIy0tLS0tLS0tLS0gVCAgbyAgZCAgbyAgcyAtLS0tLS0tLS0tDkFndWFzY2FsaWVudGVzD0JhamEgQ2FsaWZvcm5pYRNCYWphIENhbGlmb3JuaWEgU3VyCENhbXBlY2hlFENvYWh1aWxhIGRlIFphcmFnb3phBkNvbGltYQdDaGlhcGFzCUNoaWh1YWh1YRFDaXVkYWQgZGUgTcOpeGljbwdEdXJhbmdvCkd1YW5hanVhdG8IR3VlcnJlcm8HSGlkYWxnbwdKYWxpc2NvB03DqXhpY28UTWljaG9hY8OhbiBkZSBPY2FtcG8HTW9yZWxvcwdOYXlhcml0C051ZXZvIExlw7NuBk9heGFjYQZQdWVibGEKUXVlcsOpdGFybwxRdWludGFuYSBSb28QU2FuIEx1aXMgUG90b3PDrQdTaW5hbG9hBlNvbm9yYQdUYWJhc2NvClRhbWF1bGlwYXMIVGxheGNhbGEfVmVyYWNydXogZGUgSWduYWNpbyBkZSBsYSBMbGF2ZQhZdWNhdMOhbglaYWNhdGVjYXMVIQIwMAIwMQIwMgIwMwIwNAIwNQIwNgIwNwIwOAIwOQIxMAIxMQIxMgIxMwIxNAIxNQIxNgIxNwIxOAIxOQIyMAIyMQIyMgIyMwIyNAIyNQIyNgIyNwIyOAIyOQIzMAIzMQIzMhQrAyFnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dkZAIdDzwrAAsAZBgBBR5fX0NvbnRyb2xzUmVxdWlyZVBvc3RCYWNrS2V5X18WAQULYnRuRGVzY2FyZ2GnzoGsss2HRBClvJXWBp0BOLrkzw==',
        '__EVENTVALIDATION' => '/wEWKAKrvcvxDwLG/OLvBgLWk4iCCgLWk4SCCgLWk4CCCgLWk7yCCgLWk7iCCgLWk7SCCgLWk7CCCgLWk6yCCgLWk+iBCgLWk+SBCgLJk4iCCgLJk4SCCgLJk4CCCgLJk7yCCgLJk7iCCgLJk7SCCgLJk7CCCgLJk6yCCgLJk+iBCgLJk+SBCgLIk4iCCgLIk4SCCgLIk4CCCgLIk7yCCgLIk7iCCgLIk7SCCgLIk7CCCgLIk6yCCgLIk+iBCgLIk+SBCgLLk4iCCgLLk4SCCgLLk4CCCgLL+uTWBALa4Za4AgK+qOyRAQLI56b6CwL1/KjtBclG5zircigdcH9+azzOEUlhM6QP',
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
