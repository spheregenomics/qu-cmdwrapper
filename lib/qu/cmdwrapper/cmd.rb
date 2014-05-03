#!/usr/bin/env ruby

require 'open3'
require 'tempfile'
require 'qu/utils'

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

    def ntthal(s1:, s2: nil, mv: 50, dv: 1.5, d: 50, n: 0.25, mode: 'ANY', tm_only: false)
      cmd = File.join(BIN_PATH, 'ntthal')

      if s2
        # tm = `#{cmd} -mv #{mv} -dv #{dv} -d #{d} -n #{n} -s1 #{s1} -s2 #{s2} -r -path #{THERMO_PATH} -a #{mode}`
        # out = `#{cmd} -mv #{mv} -dv #{dv} -d #{d} -n #{n} -s1 #{s1} -s2 #{s2} -path #{THERMO_PATH} -a #{mode}`
        out = system_quietly("#{cmd} -mv #{mv} -dv #{dv} -d #{d} -n #{n} -s1 #{s1} -s2 #{s2} -path #{THERMO_PATH} -a #{mode}")
      else
        # out = `#{cmd} -mv #{mv} -dv #{dv} -d #{d} -n #{n} -s1 #{s1} -path #{THERMO_PATH} -a HAIRPIN`
        out = system_quietly("#{cmd} -mv #{mv} -dv #{dv} -d #{d} -n #{n} -s1 #{s1} -path #{THERMO_PATH} -a HAIRPIN")
      end

      begin
        lines = out.lines

        tm = nil
        dg = nil
        if lines.shift =~ /.*dG\s+=\s+(-?\d+\.?\d+)\s+t\s+=\s+(\d+\.?\d+)/
          dg = $1.to_f / 1000
          tm = $2.to_f
        end

        if tm_only
          return tm
        end

        lines = lines.map {|line| line.split("\t")[1].chomp}

        if s2
          seq_1 = ''
          align = ''
          seq_2 = ''
          # puts lines
          (0...lines[0].size).each do |index|
            if lines[1][index] != ' '
              seq_1 << lines[1][index]
              seq_2 << lines[2][index]
              align << '|'
            else
              align << ' '
              seq_1 << lines[0][index]
              seq_2 << lines[3][index]
            end
          end

          seq_1.sub!(/\-+$/, '')
          return tm, dg, seq_1, align, seq_2

        else
          align = lines[0]
          seq = lines[1]

          return tm, dg, seq, align
        end

      rescue Exception => e

        if tm_only
          return 0
        else
          if s2
            return nil, nil, '', '', ''
          else
            return nil, nil, '', ''
          end
        end
      end

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

    def get_binding_seq_list(binding_range_list, twobit_file) 
      amp_seq_list = []
      
      return amp_seq_list if binding_range_list.empty?

      begin
        fh = Tempfile.new('binding_range_list')
        fh.write(binding_range_list.join("\n"))
        fh.close
        amp_seq_list = twoBitToFa(fh.path, twobit_file)
      ensure
        fh.unlink
      end
      return amp_seq_list   
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

  p1 = 'tccctcctctacaactACCTCGC'
  p2 = 'TTGGTCGAGGGGAACAGCAGGT'
  p3 = 'TGTGTGCAGCTGCTGGTGGC'
  # p1 = 'act'
  # p2 = 'ctt'
  puts Qu::Cmdwrapper::ntthal(s1: p1, s2: p2, tm_only: false)
  puts Qu::Cmdwrapper::ntthal(s1: p1)
  puts Qu::Cmdwrapper::ntthal(s1: p2)
  puts Qu::Cmdwrapper::ntthal(s1: p3)
end
