require! {
  fs
  request
  nodemailer
  dropbox: Dropbox
  'prelude-ls': {map}
  'child_process': {spawn}
  'mjpeg-consumer': MjpegConsumer
  'motion': Stream: MotionStream
  './settings.json': settings
}

try
  require! {
    say
    'node-notifier': notifier
  }

consumer = new MjpegConsumer!
motion = new MotionStream settings.motion
transporter = nodemailer.createTransport do
  service: settings.mail.service
  auth: settings.mail
client = new Dropbox.Client settings.dropbox

client.authDriver new Dropbox.AuthDriver.NodeServer(8191)
error, client <- client.authenticate
console.error error if error

ffmpeg = null

motion.on 'motion_start', (frame) !->
  frame.time = new Date frame.time
  console.log "motion_start #{frame.time}"

  if notifier
    notifier.notify do
      'title': 'Attenzione!'
      'message': 'Intruder! Eindringling!'
  say.speak 'Alex', 'Intruder! Eindringling!' if say

  ffmpeg := spawn('avconv', <[-f image2pipe -r 8 -c:v mjpeg -i - -f avi -c:v libx264 pipe:1]>)
  motion.pipe ffmpeg.stdin
  ffmpeg.stdout.pipe fs.createWriteStream("./video/#{frame.time}.avi")

motion.on 'motion_stop', (frame) !->
  frame.time = new Date frame.time
  console.log 'motion_stop'

  ffmpeg.on 'exit', !->
    error, file <-! fs.readFile "./video/#{frame.time}.avi"
    console.error error if error
    error, stat <-! client.writeFile "#{frame.time}.avi", file
    console.error error if error
    console.log "Dropbox upload completed #{frame.time}.avi" if not error
  ffmpeg.stdin.end!

motion.on 'key_frames', (frames) !->
  transporter.sendMail do
    to: settings.mail.recipients
    subject: "MARTHA #{new Date(frames.1.time)}"
    attachments: map do
      (frame) ->
        filename: "#{new Date(frame.time)}.jpeg"
        contentType: 'image/jpeg'
        content: frame.data
      frames
    (err, info) ->
      console.error err if err
      console.log "mail sent to #{info.accepted}" if not err

request
  .get settings.cam.url
  .auth settings.cam.user, settings.cam.pass
  .on 'error', (err) !-> console.error err
  .on 'response', (response) !-> console.log response.statusCode
  .pipe consumer
  .pipe motion
