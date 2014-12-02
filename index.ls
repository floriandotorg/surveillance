require! {
  fs
  request
  nodemailer
  './settings.json': settings
  'child_process': {spawn}
  'mjpeg-consumer': MjpegConsumer
  'motion': Stream: MotionStream
}

try
  require! {
    say
    'node-notifier': notifier
  }

consumer = new MjpegConsumer!
motion = new MotionStream do
  threshold: settings.motion.threshold
  prebuffer: settings.motion.prebuffer
  postbuffer: settings.motion.postbuffer
transporter = nodemailer.createTransport do
  service: settings.mail.service
  auth:
    user: settings.mail.user
    pass: settings.mail.pass

ffmpeg = null

motion.on 'motion_start', (frame) !->
  frame.time = new Date frame.time
  console.log "motion_start #{frame.time}"

  if notifier
    notifier.notify do
      'title': 'Attenzione!'
      'message': 'Intruder! Eindringling!'
  say.speak 'Alex', 'Intruder! Eindringling!' if say

  transporter.sendMail do
    to: settings.mail.recipients
    subject: "MARTHA #{frame.time}"
    attachments: [
      filename: "#{frame.time}.jpeg"
      contentType: 'image/jpeg'
      content: frame.data ]
    (err, info) ->
      console.error err if err
      console.log "mail sent to #{info.accepted}" if not err

  ffmpeg := spawn('avconv', <[-f image2pipe -r 15 -c:v mjpeg -i - -f avi -c:v libx264 pipe:1]>)
  ffmpeg.stdout.pipe fs.createWriteStream("./video/#{frame.time}.avi")
  motion.pipe ffmpeg.stdin

motion.on 'motion_stop', !->
  console.log 'motion_stop'
  ffmpeg.stdin.end!

request
  .get settings.cam.url
  .auth settings.cam.user, settings.cam.pass
  .on 'error', (err) !-> console.error err
  .on 'response', (response) !-> console.log response.statusCode
  .pipe consumer
  .pipe motion
