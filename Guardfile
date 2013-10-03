guard :shell do
  watch %r'templates/.*\.tmpl' do
    `killall -HUP main`
  end
end

guard :sass, input: 'static'

guard :livereload, port: '8080' do
  watch %r'static/.*\.(css|js|svg|png)$'
  watch %r'templates/.*\.tmpl$'
end
