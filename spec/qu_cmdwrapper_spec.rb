require 'spec_helper'
describe Qu::Cmdwrapper do
  it 'should return a list' do
    p1 = 'tccctcctctacaactACCTCGC'
    p2 = 'TTGGTCGAGGGGAACAGCAGGT'
    p3 = 'TGTGTGCAGCTGCTGGTGGC'
    # p1 = 'act'
    # p2 = 'ctt'
    # p Qu::Cmdwrapper::ntthal(s1: p1, s2: p2, tm_only: true)
    # p Qu::Cmdwrapper::ntthal(s1: p1)
    # p Qu::Cmdwrapper::ntthal(s1: p2)
    Qu::Cmdwrapper::ntthal(s1: p3)[-1].should eq '------//-/----\\-\\\\--'
  end
end