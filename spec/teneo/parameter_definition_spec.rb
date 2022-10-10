# encoding: utf-8

require "teneo/tools/parameter/definition"

RSpec.describe Teneo::Tools::Parameter::Definition do
  before :context do
    @parameter_types = %w'bool string int float datetime'

    @bool_parameter = ::Teneo::Tools::Parameter::Definition.new(name: "BoolParam", default: true)
    @string_parameter = ::Teneo::Tools::Parameter::Definition.new(name: "StringParam", default: "default string")
    @int_parameter = ::Teneo::Tools::Parameter::Definition.new(name: "IntParam", default: 5)
    @float_parameter = ::Teneo::Tools::Parameter::Definition.new(name: "FloatParam", default: 1.0)
    @datetime_parameter = ::Teneo::Tools::Parameter::Definition.new(name: "DateTimeParam", default: DateTime.now)

    @constrained_bool_parameter = ::Teneo::Tools::Parameter::Definition.new(name: "TrueParam", default: true, constraint: true)
    @constrained_string_parameter = ::Teneo::Tools::Parameter::Definition.new(name: "CodeParam", default: "default string", constraint: /^ABC.*XYZ$/i)
    @constrained_int_parameter = ::Teneo::Tools::Parameter::Definition.new(name: "OddParam", default: 5, constraint: [1, 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37])
    @constrained_float_parameter = ::Teneo::Tools::Parameter::Definition.new(name: "LessThanPiParam", default: 0.0, constraint: 1.0...3.1415927)
  end

  it "should detect datatype from default value" do
    @parameter_types.each do |dtype|
      expect(eval("@#{dtype}_parameter").send(:guess_datatype)).to eq dtype
    end
  end

  it "should return default value" do
    @parameter_types.each do |dtype|
      expect(eval("@#{dtype}_parameter").parse).to eq eval("@#{dtype}_parameter").default
    end
  end

  it "should test if boolean value is valid" do
    [false, true, nil, "true", "false", "T", "F", "y", "n", 1, 0].each do |v|
      # noinspection RubyResolve
      expect(@bool_parameter).to be_valid_value(v)
    end

    [5, 0.1, "abc"].each do |v|
      # noinspection RubyResolve
      expect(@bool_parameter).not_to be_valid_value(v)
    end
  end

  it "should test if string value is valid" do
    ["abc", true, false, nil, 1, 1.0, Object.new].each do |v|
      # noinspection RubyResolve
      expect(@string_parameter).to be_valid_value(v)
    end
  end

  it "should test if integer value is valid" do
    [0, 5, -6, 3.1415926, "3", nil, Rational("1/3")].each do |v|
      # noinspection RubyResolve
      expect(@int_parameter).to be_valid_value(v)
    end

    ["abc", "3.1415926", "1 meter", false, true, Object.new].each do |v|
      # noinspection RubyResolve
      expect(@int_parameter).not_to be_valid_value(v)
    end
  end

  it "should test if float value is valid" do
    [1.1, Rational("1/3"), 3.1415926, "3.1415926", nil].each do |v|
      # noinspection RubyResolve
      expect(@float_parameter).to be_valid_value(v)
    end

    ["abc", "1.0.0", false, true, Object.new].each do |v|
      # noinspection RubyResolve
      expect(@float_parameter).not_to be_valid_value(v)
    end
  end

  it "should test if datetime value is valid" do
    [Time.now, Date.new, "10:10", "2014/01/01", "2014/01/01 10:10:10.000001", nil].each do |v|
      # noinspection RubyResolve
      expect(@datetime_parameter).to be_valid_value(v)
    end

    ["abc", 5, false].each do |v|
      # noinspection RubyResolve
      expect(@datetime_parameter).not_to be_valid_value(v)
    end
  end

  it "should accept and convert value for boolean parameter" do
    ["true", "True", "TRUE", "tRuE", "t", "T", "y", "Y", "1", 1].each do |v|
      expect(@bool_parameter.parse(v)).to be_truthy
    end

    ["false", "False", "FALSE", "fAlSe", "f", "F", "n", "N", "0", 0].each do |v|
      expect(@bool_parameter.parse(v)).to be_falsey
    end
  end

  # noinspection RubyResolve
  it "should check values against constraint" do
    expect(@constrained_bool_parameter).to be_valid_value(true)
    expect(@constrained_bool_parameter).to be_valid_value("y")

    expect(@constrained_bool_parameter).not_to be_valid_value(false)
    expect(@constrained_bool_parameter).not_to be_valid_value("n")

    %w'ABCXYZ ABC123XYZ abcxyz AbC__++__xYz'.each do |v|
      # noinspection RubyResolve
      expect(@constrained_string_parameter).to be_valid_value(v)
    end

    %w'ABC XYZ ABC123'.each do |v|
      # noinspection RubyResolve
      expect(@constrained_string_parameter).not_to be_valid_value(v)
    end

    [1, 7, 11, nil].each do |v|
      # noinspection RubyResolve
      expect(@constrained_int_parameter).to be_valid_value(v)
    end

    [0, 4, 9, 43].each do |v|
      # noinspection RubyResolve
      expect(@constrained_int_parameter).not_to be_valid_value(v)
    end

    [1.0, 3.1415, 2.718281828459].each do |v|
      # noinspection RubyResolve
      expect(@constrained_float_parameter).to be_valid_value(v)
    end

    [nil, 0.5, -2.5].each do |v|
      # noinspection RubyResolve
      expect(@constrained_float_parameter).not_to be_valid_value(v)
    end
  end

  it "should allow to set and get options" do
    @bool_parameter[:my_value] = :dummy_value

    expect(@bool_parameter[:my_value]).to be :dummy_value
    expect(@bool_parameter[:options][:my_value]).to be :dummy_value
  end
end
