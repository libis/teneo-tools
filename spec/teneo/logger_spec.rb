# frozen_string_literal: true

require "teneo/tools/logger"
require "amazing_print"

require "timecop"
TIME = Time.now
TIMESTRING = TIME.strftime("%Y-%m-%dT%H:%M:%S.%6N")

class TestLogger
  include Teneo::Tools::Logger

  def initialize(name = nil)
    @name = name
  end

  def logger_name
    @name || super
  end

  def init
    @message = @data = @exception = @duration = @metric = @metric_amount = nil
  end

  def test_logs(message: "message")
    trace message
    debug message
    info message
    warn message
    error message
    fatal message
    flush
    init
    @message = message
  end

  def test_data(message: "message", data:)
    info message, payload: data
    flush
    init
    @message = message
    @data = data
  end

  def test_hash(message: "message", hash:)
    error message, payload: hash
    flush
    init
    @message = message
    @data = hash
  end

  def test_exception(message: "message", exception:)
    fatal message, exception: exception
    flush
    init
    @message = message
    @exception = exception
  end

  def test_full(message: nil, payload: nil, exception: nil, duration: nil)
    debug message, payload: payload, exception: exception, duration: duration
    flush
    init
    @message = message
    @data = payload
    @exception = exception
    @duration = duration
  end

  def log_regex(level: "DEBUG", name: nil)
    proc_info = "#{Process.pid}\\.#{Thread.current.object_id}( #{File.basename(__FILE__)}:\\d+)?"
    proc_info = "#{Process.pid}\\.#{Thread.current.object_id}"
    level_info = "%5s" % level
    context_info = "#{logger_name}"
    duration_info = format(' \\(%0.1f ms\\)', @duration) if @duration.is_a?(Numeric)
    message_list = []
    message_list << "#{@data.to_s} ;" if @data
    message_list << "#{@message}"
    message_list << "# Exception: #{@exception.class.name} - #{@exception.to_s}" if @exception
    message = message_list.compact.join " "
    /^#{"%.1s" % level}, \[#{TIMESTRING} ##{proc_info}\] #{level_info} -- #{context_info}#{duration_info} : #{message}$/
  end
end

RSpec.describe Teneo::Tools::Logger do
  before(:all) do
    Timecop.freeze(TIME)
  end

  after(:all) do
    Timecop.return
  end

  before(:each) do
    @tl = TestLogger.new
  end

  after(:each) do
    @tl.clear_appenders!
  end

  context "without appender" do
    it "does not output anything" do
      expect {
        @tl.test_logs
      }.to output("").to_stdout_from_any_process
    end
  end

  context "with stdout appender" do
    it "prints message on stdout" do
      @tl.add_appender(:stdout, level: :debug)
      expect {
        @tl.test_full message: "printed string on stdout"
      }.to output(/ : printed string on stdout$/).to_stdout_from_any_process
    end
  end

  context "with StringIO appender" do
    before(:each) do
      @output = @tl.add_appender(:string_io, "output", level: :trace).sio
    end

    after(:each) do
      # puts "Output:"
      # puts @output.string
    end

    it "performs standard logging operations" do
      @tl.test_logs
      @output.string.split("\n").each_with_index do |l, i|
        expect(l).to match @tl.log_regex(level: %w"TRACE DEBUG INFO WARN ERROR FATAL"[i])
      end
    end

    it "performs logging with data" do
      @tl.test_data data: { data1: "abc", data2: "xyz" }
      expect(@output.string).to match @tl.log_regex(level: "INFO")
    end

    it "performs logging with hash" do
      @tl.test_hash hash: { data1: "abc", data2: "xyz" }
      expect(@output.string).to match @tl.log_regex(level: "ERROR")
    end

    it "performs logging with exception" do
      @tl.test_exception exception: RuntimeError.new("Some error occurred")
      expect(@output.string).to match @tl.log_regex(level: "FATAL")
    end

    it "performs full-option logging" do
      @tl.test_full(message: "message", payload: { data1: "abc", data2: "xyz" },
                    exception: RuntimeError.new("Some error occurred"),
                    duration: 10)
      expect(@output.string).to match @tl.log_regex(level: "DEBUG")
    end
  end

  context "with two loggers" do
    before(:each) do
      @tl1 = TestLogger.new("abcdef")
      @tl2 = TestLogger.new("xyz123")
      @output1 = @tl1.add_appender(:string_io, "output1", level: :info).sio
      @output2 = @tl2.add_appender(:string_io, "output2", level: :debug).sio
      @output3 = @tl2.add_appender(:string_io, "output3", level: :debug, level_filter: [:info, :error]).sio
      @tl1.test_logs
      @tl2.test_logs
    end

    after(:each) do
      # puts "Output1:"
      # puts @output1.string
      # puts "Output2:"
      # puts @output2.string
      # puts "Output3:"
      # puts @output3.string
      @tl1.clear_appenders!
      @tl2.clear_appenders!
    end

    it "and each has a separate log" do
      expect(@output1.string.split("\n").size).to eq 4
      @output1.string.split("\n").each_with_index do |l, i|
        expect(l).to match @tl1.log_regex(level: %w"INFO WARN ERROR FATAL"[i], name: "abcdef")
      end
      expect(@output2.string.split("\n").size).to eq 5
      @output2.string.split("\n").each_with_index do |n, i|
        expect(n).to match @tl2.log_regex(level: %w"DEBUG INFO WARN ERROR FATAL"[i], name: "xyz123")
      end
    end

    it "and filter can overrule" do
      expect(@output3.string.split("\n").size).to eq 2
      @output3.string.split("\n").each_with_index do |n, i|
        expect(n).to match @tl2.log_regex(level: %w"INFO ERROR"[i], name: "xyz123")
      end
    end
  end
end
