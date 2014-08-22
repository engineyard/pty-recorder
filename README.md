# PTY::Recorder

Run any interactive command in a PTY, while being able to record any input or output (including stderr).

PTY::Recorder acts like a middleman for fully interactive unix command sessions. Much like the script command or other terminal recording libraries, you can record everything that is input or output.

The advantage of this gem is that it can be invoked programatically. The end user will be presented with the interface to the command session with no apparent changes, but the parent process can oversee the interaction.

Input and Output streams are handled in much the same way as a normal ruby command runner. Any interactive sessions like pry, irb, ssh, bash, vim, and more can be invoked through PTY::Recorder to record everything that is input or output.

## Usage

Basic command running:

    inlog = ""
    PTYRecorder.spawn('irb --simple-prompt', inlog: inlog) # blocks until user exits irb
    puts "You typed:"
    puts inlog.inspect

