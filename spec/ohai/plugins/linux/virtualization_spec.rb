#
# Author:: Thom May (<thom@clearairturbulence.org>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.join(File.dirname(__FILE__), '..', '..', '..', '/spec_helper.rb')

describe Ohai::System, "Linux virtualization platform" do
  before(:each) do
    @ohai = Ohai::System.new
    @ohai[:os] = "linux"
    @ohai.stub!(:require_plugin).and_return(true)
    @ohai.extend(SimpleFromFile)
    File.stub!(:exists?).with("/proc/cpuinfo").and_return(false)
    File.stub!(:exists?).with("/proc/modules").and_return(false)
    File.stub!(:exists?).with("/proc/xen/capabilities").and_return(false)
    File.stub!(:exists?).with("/proc/sys/xen/independent_wallclock").and_return(false)
    File.stub!(:exists?).with("/usr/sbin/dmidecode").and_return(false)
  end

  describe "when we are involved with xen" do
    it "should set xen host if /proc/xen/capabilities contains control_d" do
      File.stub!(:read).and_return("control_d")
      File.stub!(:exists?).with("/proc/xen/capabilities").and_return(true)
      @ohai._require_plugin("linux::virtualization")
      @ohai[:virtualization][:system].should eql("xen")
      @ohai[:virtualization][:role].should eql("host")
    end

    it "should set xen guest if /proc/sys/xen/independent_wallclock exists" do
      File.stub!(:exists?).with("/proc/sys/xen/independent_wallclock").and_return(true)
      @ohai._require_plugin("linux::virtualization")
      @ohai[:virtualization][:system].should eql("xen")
      @ohai[:virtualization][:role].should eql("guest")
    end
  
    it "should not set virtualization if xen isn't there" do
      File.stub!(:exists?).with("/proc/xen/capabilities").and_return(false)
      File.stub!(:exists?).with("/proc/sys/xen/independent_wallclock").and_return(false)
      @ohai._require_plugin("linux::virtualization")
      @ohai[:virtualization].should eql( {} )
    end
  
  end

  describe "when we are involved with kvm" do
    it "should set kvm host if /proc/modules reports such" do
      File.stub!(:exists?).with("/proc/modules").and_return(true)
      File.stub!(:read).and_return("kvm                   165872  1 kvm_intel")
      @ohai._require_plugin("linux::virtualization")
      @ohai[:virtualization][:system].should eql("kvm")
      @ohai[:virtualization][:role].should eql("host")
    end
  
    it "should set kvm guest if /proc/cpuinfo shows QEMU" do
      File.stub!(:exists?).with("/proc/cpuinfo").and_return(true)
      File.stub!(:read).and_return("model name  : QEMU Virtual CPU version 0.9.1")
      @ohai._require_plugin("linux::virtualization")
      @ohai[:virtualization][:system].should eql("kvm")
      @ohai[:virtualization][:role].should eql("guest")
    end

    it "should not set kvm host if /proc/modules does not exist" do
      @ohai._require_plugin("linux::virtualization")
      @ohai[:virtualization].should eql( {} )
    end
  end
end


