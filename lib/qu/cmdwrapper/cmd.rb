#!/usr/bin/env ruby

require 'open3'
require 'tempfile'

module Qu
  module Cmdwrapper
    BIN_ROOT = File.join(__dir__, 'ext_bin')
    BIN_PATH = File.join(BIN_ROOT, Utils::platform_os, Utils::platform_bit.to_s)


    THERMO_PATH = File.join(__dir__, 'primer3_config') + '/'

    module_function

    def primer3_core(p3_input_file)
      begin
        cmd = File.join(BIN_PATH, 'primer3_core')
        begin
          return system_quietly("#{cmd} #{File.realpath(p3_input_file)}")
        rescue ShellError
          return ''
        end
      rescue IOError
        $stderr.puts "Primer3 input file not exists: #{p3_input_file}"
        exit
      end
    end

    def ntthal(s1, s2=nil, mv=50, dv=1.5, d=50, n=0.25, mode='ANY')
      cmd = File.join(BIN_PATH, 'ntthal')
      if s2
        tm = `#{cmd} -mv #{mv} -dv #{dv} -d #{d} -n #{n} -s1 #{s1} -s2 #{s2} -r -path #{THERMO_PATH} -a #{mode}`
      else
        tm = `#{cmd} -mv #{mv} -dv #{dv} -d #{d} -n #{n} -s1 #{s1} -r -path #{THERMO_PATH} -a HAIRPIN`
      end

      return tm.to_f
    end

    def faToTwoBit(fasta, twobit)
      cmd = File.join(BIN_PATH, 'faToTwoBit')
      `#{cmd} #{fasta} #{twobit}`
    end

    def twoBitToFa(seq_list_file, twobit_file)
      cmd = File.join(BIN_PATH, 'twoBitToFa')

      records = []
      begin
        out_file = Tempfile.new('twobit')
        `#{cmd} -seqList=#{seq_list_file} #{twobit_file} #{out_file.path}`
        out_file.rewind

        Bio::FlatFile.new(Bio::FastaFormat, out_file).each do |record|
          records << record.naseq.seq
        end
      ensure
        out_file.close
        out_file.unlink
      end

      return records
    end

    class ShellError < StandardError; end

    def system_quietly(*cmd)
      exit_status=nil
      err=nil
      out=nil
      Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thread|
        err = stderr.gets(nil)
        out = stdout.gets(nil)
        [stdin, stdout, stderr].each{|stream| stream.send('close')}
        exit_status = wait_thread.value
      end
      if exit_status.to_i > 0
        err = err.chomp if err
        raise ShellError, err
      elsif out
        return out.chomp
      else
        return true
      end
    end

  end
end

if $0 == __FILE__
  puts Qu::Cmdwrapper::BIN_PATH
end
