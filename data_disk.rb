# -*- mode: ruby -*-
# vi: set ft=ruby :
#CLOUDLINK Modified file from https://gist.githubusercontent.com/darrenleeweber to deal with multiple VMs
#Shared Info

require_relative 'diskvars'

vm_name =  ""

HOME = ENV['HOME']


def vbox_manage?
  @vbox_manage ||= ! `which VBoxManage`.chomp.empty?
end

def vm_boxes
  boxes = {}
  if vbox_manage?
    vms = `VBoxManage list vms`
    vms.split("\n").each do |vm|
      x = vm.split
      k = x[0].gsub('"','')      # vm name
      v = x[1].gsub(/[{}]/,'')   # vm UUID
      boxes[k] = v
    end
  end
  boxes
end

def vm_exists?
  vm_boxes[SharedVaribles.vmcurrentname] ? true : false
end

def vm_info
  vm_exists? ? `VBoxManage showvminfo #{SharedVaribles.vmcurrentname}` : ''
end

def vm_uuid
  vm_boxes[SharedVaribles.vmcurrentname]
end

def vm_state
  case vm_exists?
  when true
    vm_state = vm_info.split("\n").select {|f| f =~ /^State:/}.first || ''
    vm_state.split[1]
  when false
    ''
  end
end

def vm_running?
  vm_state == "running"
end

def vm_stop
  case vm_exists?
  when true
    cmd = "VBoxManage controlvm #{SharedVaribles.vmcurrentname} poweroff"
    vm_running? ? system(cmd) : true
  when false
    # it is 'stopped' if it doesn't exist, but
    # this return value is the status of this operation.
    false
  end
end

# Try to identify the data disk UUID;
# this can be done whether the vm exists or not.
def data_disk_uuid
  @data_disk_uuid ||= begin
    data_disk_uuid = nil
    if vbox_manage? && data_disk_created?
      hdds = `VBoxManage list hdds`.split("\n\n")
      hd = hdds.select {|d| d =~ /#{DATA_DISK_FILE}/ }
      if hd.length == 1
        fields = hd.first.split("\n")
        uuid = fields.select {|f| f =~ /^UUID:/ }.first
        data_disk_uuid = uuid.split[1]
      end
    end
    data_disk_uuid
  end
end


# Try to detach data disk
def data_disk_detach
  vm_name =  SharedVaribles.vmcurrentname
  puts "Selected VM #{vm_name} and removing data disks.  Please run \'vagrant up --provision\' to reattach and/or power on the VM(s)"
  vm_stop
  if vm_exists? 
    cmd = [
      'VBoxManage storageattach ' + vm_uuid,
      '--storagectl "IDE Controller"',
      '--port 1',
      '--device 0',
      '--type hdd',
      '--medium none'
    ].join(' ')
    if system(cmd)
      puts 'Detached virtual data disk:'
    end
  end

end