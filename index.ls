#############

CAM_URL = 'http://192.168.2.51/videostream.cgi'
USER = 'admin'
PASS = '123456'

THRESHOLD = 0x05
PREBUFFER = 0 # +2
POSTBUFFER = 4 * 1000

#############

require! {
  fs
  request
  'child_process': {spawn}
  'mjpeg-consumer': MjpegConsumer
  'motion': Stream: MotionStream
}
consumer = new MjpegConsumer!
motion = new MotionStream do
  threshold = THRESHOLD
  prebuffer = PREBUFFER
  postbuffer = POSTBUFFER

ffmpeg = null

motion.on 'motion_start', !->
  console.log 'motion_start'

  ffmpeg := spawn('ffmpeg', <[-f image2pipe -r 15 -c:v mjpeg -i - -f avi -c:v libx264  pipe:1]>)
  ffmpeg.stdout.pipe fs.createWriteStream("./video/#{new Date!}.avi")
  motion.pipe ffmpeg.stdin

motion.on 'motion_stop', !->
  console.log 'motion_stop'
  ffmpeg.stdin.end!

request
  .get CAM_URL
  .auth USER, PASS
  .on 'error', (err) !-> console.err err
  .on 'response', (response) !-> console.log response.statusCode
  .pipe consumer
  .pipe motion
