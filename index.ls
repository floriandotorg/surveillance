require! {
  fs
  request
  'mjpeg-consumer': MjpegConsumer
}
spawn = require('child_process').spawn

consumer = new MjpegConsumer!

MotionStream = require('motion').Stream;
motion = new MotionStream();

writer = new FileOnWrite({
  path: './video/',
  ext: '.jpg'
});

ffmpeg = spawn('ffmpeg', <[-f image2pipe -c:v mjpeg -i - -f avi -c:v libx264  pipe:1]>)

ffmpeg.stderr.on 'data', (data) ->
  console.log('grep stderr: ' + data);

ffmpeg.stdout.pipe fs.createWriteStream("./video/#{new Date!}.avi")

r = request
  .get "http://192.168.2.51/videostream.cgi"
  .auth 'admin', '123456'
  .on 'error', (err) -> console.log err
  .on 'response', (response) -> console.dir response.statusCode
  .pipe consumer
  # .pipe motion
  .pipe ffmpeg.stdin
  # .pipe process.stdout
  # .pipe(writer)

# process.on 'SIGINT', -> r.abort!
