module SharedVaribles
  @vmcurrentname="Test_VM"

  def self.vmcurrentname
    return @vmcurrentname
  end

  def self.vmcurrentname=(val)
    @vmcurrentname=val;
  end
end