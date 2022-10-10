# encoding: utf-8
require_relative File.join('..', 'spec_helper')
require 'teneo/tools/checksum'

RSpec.describe Teneo::Tools::Checksum do

  def hex2base64(hexdigest)
    [[hexdigest].pack('H*')].pack('m0')
  end

  def hex2string(hexdigest)
    [hexdigest].pack('H*')
  end

  it 'should not know how to calculate ABC checksum' do

    checksum_type = :ABC

    expect {
      ::Teneo::Tools::Checksum.hexdigest('abc', checksum_type)
    }.to raise_error(RuntimeError, "Checksum type 'ABC' not supported.")

  end

  let(:filename) { File.join(File.dirname(__FILE__), 'data', 'test.data') }

  CHECKSUM_RESULTS = {
      MD5: 'fe249d8dd45a39793f315fb0734ffe2c',
      SHA1: 'e8f322d186699807a98a0cefb5015acf1554f954',
      SHA256: '2a742e643dd79427738bdc0ebd0d2837f998fe2101a964c2d5014905d331bbc4',
      SHA384: '71083b74394f49db6149ad9147103f7693ec823183750ce32a2215bbd7ee5e75212e2d794243c7e76c7318a4ddcf9a56',
      SHA512: '10964f5272729c2670ccad67754284fb06cca1387270c184c2edbcd032700548297916c8e109a10e019c25b86c646e95a3456c465f83d571502889f97b483e6f'
  }

  # noinspection RubyResolve
  unless defined? JRUBY_VERSION
    CHECKSUM_RESULTS[:RMD160] = '17c9eaad9ccbaad0e030c2c5d60fd9d58255cc39'
  end

  filename = File.join(File.dirname(__FILE__), 'data', 'test.data')
  file = File.absolute_path(filename)
  string = File.read(filename)
  SUBJECTS = {
      string: string,
      file: file
  }

  CHECKSUM_RESULTS.each do |checksum_type, digest|

    SUBJECTS.each do |subject_type, subject|

      it "should calculate #{checksum_type} from #{subject_type}" do
        expect(::Teneo::Tools::Checksum.hexdigest(subject, checksum_type)).to eq digest
        expect(::Teneo::Tools::Checksum.base64digest(subject, checksum_type)).to eq hex2base64(digest)
        expect(::Teneo::Tools::Checksum.digest(subject, checksum_type)).to eq hex2string(digest)

        checksum = ::Teneo::Tools::Checksum.new(checksum_type)

        expect(checksum.hexdigest(subject)).to eq digest
        expect(checksum.base64digest(subject)).to eq hex2base64(digest)
        expect(checksum.digest(subject)).to eq hex2string(digest)
      end

    end

  end

end