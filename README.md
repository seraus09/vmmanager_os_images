#### Шаблоны для установки CentOS / Ubuntu / Debian с разворачиванием из файла для VMManager  

Создано на основе [официального руководства](https://docs.ispsystem.ru/vmmanager-kvm/shablony-os-i-retsepty/shablony-os/sozdanie-shablonov-os#id-%D0%A1%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5%D1%88%D0%B0%D0%B1%D0%BB%D0%BE%D0%BD%D0%BE%D0%B2%D0%9E%D0%A1-CentOS%D1%81%D1%80%D0%B0%D0%B7%D0%B2%D0%BE%D1%80%D0%B0%D1%87%D0%B8%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5%D0%BC%D0%B8%D0%B7%D1%84%D0%B0%D0%B9%D0%BB%D0%B0)

Созданы шаблоны для CentOS 7, Ubuntu 18.04 / 20.04, Debian 10 / 11  

Директории шаблонов копируются в /nfsshare/  
Для использования шаблонов нужно создать образы дисков. Для этого, используя стандартные шаблоны vmmanger, устанавливаем нужную ОС, задавая размер диска указанный в шаблоне параметром ```<elem name="disk">```.  
Устанавливаем туда нужные программы. Пакеты ```cloud-utils-growpart``` / ```cloud-guest-utils``` необходимы для работы скрипта, остальное опционально.  
Пример для CentOS 7  

```bash
yum install -y epel-release
yum install -y cloud-utils-growpart bind-utils traceroute bash-completion bash-completion-extras nano ncdu net-tools wget byobu deltarpm
```

Пример для Ubuntu 18.04 / 20.04  

```bash
apt install -y cloud-guest-utils dnsutils traceroute bash-completion nano ncdu net-tools wget byobu locales-all
```

Удаляем из ```/etc/sysconfig/network-scripts/ifcfg-eth0```
опцию ```HWADDR``` и меняем ```NAME``` на ```DEVICE```  

Добавляем команду для запуска скрипта  
В CentOS 7

```bash
echo "sh /dev/sda" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
```

В Ubuntu / Debian файла ```/etc/rc.local``` нет. Создаём его.

```bash
printf '%s\n' '#!/bin/bash' 'bash /dev/sda' 'exit 0' | tee /etc/rc.local
chmod +x /etc/rc.local
```

Останавливаем vm и снимаем образ.  

```bash
# Мой пример
dd if=/dev/virtual/vm6889  of=/nfsshare/IMG_BitrixEnv-7-amd64_ext4/bitrixenv_7_hdd.image bs=16M

# Из документации vmmanger  
# Для LVM
dd if=/dev/MyLvm/VMNAME of=centos_hdd.image
# Для формата RAW/Qcow2
dd if=ПУТЬ_К_ФАЙЛУ of=centos_hdd.image
```

После чего можно подключать шаблоны к обработчикам / тарифам / типам продуктов.  

##### Особенности  

- Поддерживается создание vm с несколькими ip. Если ip добавлены после создания vm, то их нужно добавить вручную.  
  Billmanager при заказе vm с несколькими ip, сначала создаёт vm с одним ip, а остальные добавляет позже, так что нужно или добавлять их вручную или производить переустановку ОС через панель vmmanager.
- Смена ip после создания vm также вручную.  
- Работа с ipv6 не проверена.  

##### Для более удобного обновления скриптов

```bash
cd /opt/
git clone https://github.com/YogSottot/vmmanager_os_images
cd vmmanager_os_images
cat .git/hooks/post-merge 
#!/bin/sh

ln -f $GIT_DIR/../IMG_CentOS-7-amd64_ext4/metainfo.xml /nfsshare/IMG_CentOS-7-amd64_ext4/
ln -f $GIT_DIR/../IMG_CentOS-7-amd64_ext4/install.sh /nfsshare/IMG_CentOS-7-amd64_ext4/

ln -f $GIT_DIR/../IMG_BitrixEnv-7-amd64_ext4/metainfo.xml /nfsshare/IMG_BitrixEnv-7-amd64_ext4/
ln -f $GIT_DIR/../IMG_BitrixEnv-7-amd64_ext4/install.sh /nfsshare/IMG_BitrixEnv-7-amd64_ext4/

ln -f $GIT_DIR/../IMG_Ubuntu-18.04-amd64/metainfo.xml /nfsshare/IMG_Ubuntu-18.04-amd64/
ln -f $GIT_DIR/../IMG_Ubuntu-18.04-amd64/install.sh /nfsshare/IMG_Ubuntu-18.04-amd64/

ln -f $GIT_DIR/../IMG_Ubuntu-20.04-amd64/metainfo.xml /nfsshare/IMG_Ubuntu-20.04-amd64/
ln -f $GIT_DIR/../IMG_Ubuntu-20.04-amd64/install.sh /nfsshare/IMG_Ubuntu-20.04-amd64/

ln -f $GIT_DIR/../IMG_Debian-10-amd64/metainfo.xml /nfsshare/IMG_Debian-10-amd64/
ln -f $GIT_DIR/../IMG_Debian-10-amd64/install.sh /nfsshare/IMG_Debian-10-amd64/

ln -f $GIT_DIR/../IMG_Debian-11-amd64/metainfo.xml /nfsshare/IMG_Debian-11-amd64/
ln -f $GIT_DIR/../IMG_Debian-11-amd64/install.sh /nfsshare/IMG_Debian-11-amd64/

```

При ```git pull``` скрипты будут обновляться на новую версию.  
Директории в ```/nfsshare/``` нужно предварительно создать.
