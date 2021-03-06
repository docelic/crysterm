require "mutex"

require "event_handler"

module Crysterm
  # A display / physical display for Crysterm. Can be created on anything that is an IO.
  #
  # If a `Display` object is not explicitly created, its creation will be
  # implicitly performed at the time of creation of first `Screen`.
  class Display
    include EventHandler # Event model

    # List of existing instances.
    #
    # For automatic management of this list, make sure that `#bind` is called at
    # creation of `Display`s and that `#destroy` is called at termination.
    #
    # `#bind` does not have to be called explicitly because it happens during `#initialize`.
    # `#destroy` does need to be called.
    class_getter instances = [] of self

    # Returns number of created `Display` instances
    def self.total
      @@instances.size
    end

    # Creates and/or returns the "global" (first) instance of `Display`.
    #
    # An alternative approach, which is currently not implemented, would be to hold the global `Display`
    # in a class variable, and return it here. In that way, the choice of the default/global `Display`
    # at a particular time would be configurable in runtime.
    def self.global(create = true)
      (instances[0]? || (create ? new : nil)).not_nil!
    end

    # :nodoc: Flag indicating whether at least one `Display` has called `#bind`.
    @@_bound = false

    # Force Unicode (UTF-8) even if auto-detection did not discover terminal support for it?
    property? force_unicode = false

    # True if the `Display` objects are being destroyed to exit program; otherwise returns false.
    # property? exiting : Bool = false

    # True if/after `#destroy` has ran.
    property? destroyed = false

    # Default application title, inherited by `Screen`s
    getter title : String? = nil

    # Input IO
    property input : IO::FileDescriptor = STDIN.dup

    # Output IO
    property output : IO::FileDescriptor = STDOUT.dup

    # Access to instance of `Tput`, used for affecting the terminal/IO.
    getter! tput : ::Tput
    # XXX Any way to succeed turning this into `getter` without `!`?

    # :nodoc:
    @_listened_keys : Bool = false
    # XXX groom this

    @mutex = Mutex.new

    def initialize(
      input = STDIN.dup,
      output = STDOUT.dup,
      @use_buffer = false,
      @force_unicode = false,
      terminfo : Bool | Unibilium::Terminfo = true,
      @term = ENV["TERM"]? || "{% if flag?(:screens) %}screens-ansi{% else %}xterm{% end %}"
    )
      # TODO make these check @output, not STDOUT which is probably used.
      @cols = ::Term::Screen.cols || 1
      @rows = ::Term::Screen.rows || 1

      @terminfo = case terminfo
                  when true
                    Unibilium::Terminfo.from_env
                  when false
                    nil
                  when Unibilium::Terminfo
                    terminfo.as Unibilium::Terminfo
                  end

      @tput = ::Tput.new(
        terminfo: @terminfo,
        input: input,
        output: output,
        # TODO these options
        # term: @term,
        # padding: @padding,
        # extended: @extended,
        # termcap: @termcap,
        use_buffer: @use_buffer,
        force_unicode: @force_unicode
      )

      @mutex.synchronize do
        unless @@instances.includes? self
          @@instances << self
          return if @@_bound
          @@_bound = true
          # ... Can do anything else here, which will execute only for first
          # display created in the program
        end
      end

      listen
    end

    # Sets title locally and in the terminal's screen bar when possible
    def title=(@title)
      @tput.title = @title
    end

    # Displays the main screen, set up IO hooks, and starts the main loop.
    #
    # This is similar to how it is done in the Qt framework.
    #
    # This function will render the specified `screen` or global `Screen`.
    #
    # Note that if using multiple `Display`s, currently you should provide `screen` argument explicitly.
    def exec(screen : Crysterm::Screen? = nil)
      if w = screen || Crysterm::Screen.global
        w.render
      else
        # XXX This part might be changed in the future, if we allow running line-
        # rather than screen-based apps, or if we allow something headless.
        raise Exception.new "No Screen exists, there is nothing to render and run."
      end

      listen

      # The main loop is currently just a sleep :)
      sleep
    end

    # Sets up IO listeners for keyboard (and mouse, but mouse is currently unsupported).
    def listen
      # Potentially reset screen title on exit:
      # if !rxvt?
      #  if !vte?
      #    set_title_mode_feature 3
      #  end
      #  manipulate_screen(21) { |err, data|
      #    return if err
      #    @_original_title = data.text
      #  }
      # end

      # Listen for keys/mouse on input
      # if (@tput.input._our_input == 0)
      #  @tput.input._out_input = 1
      _listen_keys
      # _listen_mouse
      # else
      #  @tput.input._our_input += 1
      # end

      # on(AddHandlerEvent) do |wrapper|
      #  if wrapper.event.is_a?(Event::KeyPress) # or Event::Mouse
      #    # remove self...
      #    if (@tput.input.set_raw_mode && !@tput.input.raw?)
      #      @tput.input.set_raw_mode true
      #      @tput.input.resume
      #    end
      #  end
      # end
      # on(AddHandlerEvent) do |wrapper|
      #  if (wrapper.is_a? Event::Mouse)
      #    off(AddHandlerEvent, self)
      #    bind_mouse
      #  end
      # end
      # Listen for resize on output
      # if (@output._our_output==0)
      #  @output._our_output = 1
      #  _listen_output
      # else
      #  @output._our_output += 1
      # end
    end

    # :nodoc:
    def _listen_keys
      return if @_listened_keys
      @_listened_keys = true
      spawn do
        tput.listen do |char, key, sequence|
          emit Crysterm::Event::KeyPress.new char, key, sequence
        end
      end
    end

    # Destroys current `Display`
    def destroy
      Screen.instances.each &.destroy
      @@instances.delete self
      @input.cooked!
      @destroyed = true
      emit Crysterm::Event::Destroy
    end
  end
end

# TODO
# application:
# cursor.flash.time, double.click.interval,
# keyboard.input.interval, start.drag.distance,
# start.drag.time,
# stylesheet -> string
# wheelscrolllines
# close.all.screens, active.modal.screen, active.popup.screen
# active.screen, alert(), all_widgets
# Event::AboutToQuit
# ability to set terminal font
# something about effects
# NavigationMode
# palette?
# set.active.screen
