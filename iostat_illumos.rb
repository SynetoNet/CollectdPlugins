#!/usr/local/bin/ruby
#
#
# This file is part of the Syneto/CollectdPlugins package.
#
# (c) Syneto (office@syneto.net)
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.
#
# This is a collectd plugin that calls iostat infinately at the interval specified in collectd.conf.
# It requires the exec Collectd plugin so it can be executed by Collectd.
# Only one process is loaded, at the begining, when collectd starts.
# Collectd will read the process' output periodically.
#
# For information about configuring exec plugins in Collectd, see
# http://collectd.org/documentation/manpages/collectd.conf.5.shtml#plugin_exec
#
# For information about Collectd's plain text protocol, see
# https://collectd.org/wiki/index.php/Plain_text_protocol
#
# The plugin must not run as root. "nobody" is a good candidate but feel free to use your favorit user.
#
# <Plugin exec>
#    Exec "nobody" "/path/to/iostat_illumos.sh"
# </Plugin>
#

trap("TERM") {killChildAndExit}

def killChildAndExit
    puts "Killing child process: " + @iostatProcess.pid.to_s
    Process.kill("KILL", @iostatProcess.pid)
    abort("Caught TERM. Exiting...")
end

def sendToCollectd(device,type,path,metric,value)
    puts "PUTVAL " + HOSTNAME.chomp + "/iostat-" + type + "-" + device + "/gauge-" + path + "_" +  metric + " interval=" + INTERVAL.to_s + " N:" + value.to_s
end

def getPools
    zpoolListProcess = IO.popen("zpool list -H -o name")
    pools = zpoolListProcess.readlines
    zpoolListProcess.close
    return pools
end

HOSTNAME = ENV['COLLECTD_HOSTNAME'] ? ENV['COLLECTD_HOSTNAME'] : `hostname`.gsub(/\./, "_")
INTERVAL = ENV['COLLECTD_INTERVAL'] ? ENV['COLLECTD_INTERVAL'].to_i : 10

while true
    pools = getPools
    @iostatProcess = IO.popen("iostat -xn 1")
    while line = @iostatProcess.gets do
        if  ( line =~ /device/ )
            #puts "Debug: Skipped line:" + line
        else
            iops_read, iops_write, kb_read, kb_write, wait, actv, wsvc_t, asvc_t, perc_wait, perc_busy, device = line.split
            type = pools.include?(device + "\n") ? "pool" : "disk"
            sendToCollectd device, type, "iops", "read", iops_read
            sendToCollectd device, type, "iops", "write", iops_write
            sendToCollectd device, type, "bandwidth", "read", kb_read.to_i*1024
            sendToCollectd device, type, "bandwidth", "write", kb_write.to_i*1024
            sendToCollectd device, type, "wait", "transactions", wait
            sendToCollectd device, type, "active", "transactions", actv
            sendToCollectd device, type, "wait", "time", wsvc_t
            sendToCollectd device, type, "active", "service_time", asvc_t
            sendToCollectd device, type, "wait", "percent", perc_wait
            sendToCollectd device, type, "active", "percent", perc_busy
        end
    end
    @iostatProcess.close

    sleep INTERVAL
end