guard :shell do
  watch %r'templates/.*\.tmpl' do
    `killall -HUP main`
  end
  watch 'main' do
    system 'killall -INT main'
  end
end

guard :livereload, port: '8080' do
  watch %r'static/.*\.(css|js|svg|png)$'
  watch %r'templates/.*\.tmpl$'
end
