guard :sass, input: 'scss', output: 'static'

guard :shell do
  watch %r'templates/.*\.tmpl' do
    system 'killall -HUP main'
  end
  watch 'static/style.css' do
    system "csso static/style.css static/style-min.css && echo '[csso] style.css -> style-min.css'"
  end
  watch %r'coffee/.+\.coffee$' do
    system "coffee -cj static/books.js coffee/*.coffee && echo '[coffee] JS compiled'"
  end
end

guard :livereload, port: '8080' do
  watch %r'static/.*\.(css|js|svg|png)$'
  watch %r'templates/.*\.tmpl$'
end
