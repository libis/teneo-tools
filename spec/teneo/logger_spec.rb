# frozen_string_literal: true

require "amazing_print"
require "timecop"

require 'teneo/tools/logger'

TIME = Time.now
TIMESTRING = TIME.strftime("%Y-%m-%d %H:%M:%S.%6N")
SemanticLogger.default_level = :trace

class TestLogger
  include Teneo::Tools::Logger

  def initialize(name = nil)
    @name = name
  end

  def logger_name
    @name || super
  end

  def init
    @tag = @message = @data = @exception = @duration = @metric = @metric_amount = nil
  end

  def test_logs(message: "message")
    logger.trace message
    logger.debug message
    logger.info message
    logger.warn message
    logger.error message
    logger.fatal message
    flush
    init
    @message = message
  end

  def test_data(message: "message", data:)
    logger.info message, data
    flush
    init
    @message = message
    @data = data
  end

  def test_hash(message: "message", hash:)
    logger.error message: message, payload: hash
    flush
    init
    @message = message
    @data = hash
  end

  def test_exception(message: "message", exception:)
    logger.fatal message, exception
    flush
    init
    @message = message
    @exception = exception
  end

  def test_full(message: nil, payload: nil, exception: nil, duration: nil, metric: nil, metric_amount: nil, tag: nil)
    if tag
      logger.tagged(tag) do
        logger.debug message: message, payload: payload, exception: exception, duration: duration, metric: metric, metric_amount: metric_amount
      end
    else
      logger.debug message: message, payload: payload, exception: exception, duration: duration, metric: metric, metric_amount: metric_amount
    end
    flush
    init
    @tag = tag
    @message = message
    @data = payload
    @exception = exception
    @duration = duration
    @metric = metric
    @metric_amount = metric_amount
  end

  def log_regex(level: "TDIWEF", name: nil)
    proc_info = "#{Process.pid}:#{Thread.current.object_id}( #{File.basename(__FILE__)}:\\d+)?"
    tag_info = "\\[#{@tag}\\] " if @tag
    duration_info = format('\\(%0.1fms\\) ', @duration) if @duration.is_a?(Numeric)
    class_info = name || logger_name
    message = " -- #{@message}"
    message += " -- #{@data.to_s}" if @data
    message += " -- Exception: #{@exception.class.name}: #{@exception.to_s}" if @exception
    /^#{TIMESTRING} [#{level}] \[#{proc_info}\] #{tag_info}#{duration_info}#{class_info}#{message}$/
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

  context "without appender" do
    it "does not output anything" do
      expect {
        @tl.test_logs
      }.to output("").to_stdout
    end
  end

  context "with stdout appender" do

    it "prints message on stdout" do
      expect {
        @tl.add_appender(io: $stdout, level: :debug)
        @tl.test_full message: 'printed string on stdout'
      }.to output(/ -- printed string on stdout$/).to_stdout
    end


  end

  context "with StringIO appender" do
    before(:each) do
      @output = StringIO.new
      @tl.add_appender(io: @output, level: :debug)
    end

    it "performs standard logging operations" do
      @tl.test_logs
      @output.string.split("\n").each_with_index do |l, i|
        expect(l).to match @tl.log_regex(level: "DIWEF"[i])
      end
    end

    it "performs logging with data" do
      @tl.test_data data: { data1: "abc", data2: "xyz" }
      expect(@output.string).to match @tl.log_regex(level: "I")
    end

    it "performs logging with hash" do
      @tl.test_hash hash: { data1: "abc", data2: "xyz" }
      expect(@output.string).to match @tl.log_regex(level: "E")
    end

    it "performs logging with exception" do
      @tl.test_exception exception: RuntimeError.new("Some error occurred")
      expect(@output.string).to match @tl.log_regex(level: "F")
    end

    it "performs full-option logging" do
      @tl.test_full(message: "message", payload: { data1: "abc", data2: "xyz" },
                    exception: RuntimeError.new("Some error occurred"),
                    duration: 10, metric: "abc/xyz", metric_amount: 12345,
                    tag: "abc_xyz"
      )
      expect(@output.string).to match @tl.log_regex(level: "D")
    end
  end

  context "with two loggers" do
    before(:each) do
      @tl1 = TestLogger.new('abcdef')
      @tl2 = TestLogger.new('xyz123')
      @output1 = StringIO.new
      @tl1.add_appender(io: @output1, level: :debug)
      @output2 = StringIO.new
      @tl2.add_appender(io: @output2, level: :trace)
      @output3 = StringIO.new
      @tl2.add_appender(io: @output3, level: :trace, filter: nil)
      @tl1.test_logs
      @tl2.test_logs
    end

    it "and each has a separate log" do
      expect(@output1.string.split("\n").size).to eq 5
      @output1.string.split("\n").each_with_index do |l, i|
        expect(l).to match @tl1.log_regex(level: "DIWEF"[i], name: 'abcdef')
      end
      expect(@output2.string.split("\n").size).to eq 6
      @output2.string.split("\n").each_with_index do |n, i|
        expect(n).to match @tl2.log_regex(level: "TDIWEF"[i], name: 'xyz123')
      end
    end

    it "unless filter is overruled" do
      expect(@output3.string.split("\n").size).to eq 12
      @output3.string.split("\n")[0...6].each_with_index do |n, i|
        expect(n).to match @tl1.log_regex(level: "TDIWEF"[i], name: 'abcdef')
      end
      @output3.string.split("\n")[6..-1].each_with_index do |n, i|
        expect(n).to match @tl2.log_regex(level: "TDIWEF"[i], name: 'xyz123')
      end
    end
  end
end
