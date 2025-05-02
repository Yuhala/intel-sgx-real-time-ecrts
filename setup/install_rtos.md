
## About
- This readme provides instructions on how to install the real-time (RT) patch on Ubuntu 20.04 or Ubuntu 22.04 LTS and configure the system for real-time workloads.

## Manually installing RT patch for Ubuntu 20.04 LTS 
- Install compilers 
```
sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison dwarves
```
- Download kernel and real-time patch. We use kernel version `6.9.5`
```
wget https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-6.9.5.tar.xz
wget https://mirrors.edge.kernel.org/pub/linux/kernel/projects/rt/6.9/patch-6.9-rt5.patch.xz
```

- Extract kernel and apply patch
```
xz -cd linux-6.9.5.tar.xz | tar xvf -
cd linux-6.9.5
xzcat ../patch-6.9-rt5.patch.xz | patch -p1

```
- Configure new kernel
```
cp /boot/config-xxx .config

scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS "" # Very important line!!! Caused me lots of trouble: pyuhala :)
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""


yes '' | make olddefconfig

make menuconfig #select option fully preemptible
```
- Build kernel and install
```
make -j8 

```

- Install required modules.
```
sudo make modules_install -j8
sudo make install -j8
```
- Update bootloader (this is probably already done by the previous commands).
```
sudo update-initramfs -c -k 6.9.5-rt5
sudo update-grub
```
- Reboot machine and verify kernel version with `uname -mrs`



## Real time programming in Linux
- Install real time patches into Linux (PREEMPT_RT)
- Build real time program with Linux `PREEMPT_RT`.
- 

## Debugging 
- Root permissions are required to set the scheduling policy when creating a thread. So run the RT application with `sudo`.


## Server configuration for real-time
- The server used here has 16 threads. Modify related instructions accordingly.
1. Disable hyperthreading and turbo boot in BIOS.
2. Install Linux RT patch and use `PREEMPT_RT` as scheduler.
3. Grub configurations for CPU isolation: add the following in `/etc/default/grub`
```
GRUB_CMDLINE_LINUX_DEFAULT="nosmt=force irqaffinity=0-2 skew_tick=1 threadirqs isolcpus=3-15 rcu_nocbs=3-15 rcu_nocb_poll nohz=on nohz_full=2-15 intel.max_cstate=0 intel_idle.max_cstate=0 intel_pstate=disable processor.max_cstate=0 processor_idle.max_cstate=0 rdt=cmt,13cat,13cdp,mba selinux=0 audit=0 iomem=relaxed intel_iommu=on iommu=pt"

sudo update-grub
sudo reboot
```
- To list isolated CPUs, use: 
```
cat /sys/devices/system/cpu/isolated
```
4. Disable NTP daemon (the idea is to avoid the system clock from jumping when it synchronizes the time)
```
sudo timedatectl set-ntp false
```
- Re-enable this option after running cyclictest, otherwise the system clock will drift and server will be desynchronized.
5. Install `irqbalance` tool and change the two configuration variables in the `/etc/default/irqbalance` file:
```
IRQBALANCE_BANNED_CPUS=0001111111111111111111111111111111111111111111111111111111111111
IRQBALANCE_BANNED_CPULIST=3-15
```
- Update and restart the daemon
```
sudo systemctl daemon-reload
sudo systemctl restart irqbalance
```



## References
- See https://phoenixnap.com/kb/build-linux-kernel for further instructions
- https://wiki.linuxfoundation.org/realtime/documentation/howto/tools/rt-tests#compile-and-install
- See https://shuhaowu.com/blog/2022/01-linux-rt-appdev-part1.html
- https://wiki.linuxfoundation.org/realtime/documentation/howto/applications/application_base
- https://ntrs.nasa.gov/api/citations/20200002390/downloads/20200002390.pdf

