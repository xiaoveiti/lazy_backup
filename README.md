# lazy_backup

<b>lazy_backup</b> is simple and lean backup script.
Back up your folders and databases in no time! Restore them just as quickly and easily.

Please remember to create your own config file and save it in the <b>/cfg</b> folder, where you will also find sample configurations.

## Usage

```
./lazy_backup.sh <option> <config file>
```
There are several options you can choose.

```
    Options:
       -e  --export <config>		export files
       -i  --import <config>		import files
       -h  --help       		show help
```

# lazy_rclone

<b>lazy_rclone</b> helps you upload your backups to external storage e.g. AWS, Dropbox, Onedrive, etc and ensures that older backups are automatically deleted after a defined time.

Please remember to edit the <b>/rclone.cf</b> in the <b>/cfg</b> folder and make sure you allready installed and configured rclone to your personal need. In combination with daily, weekly or monthly cronjobs definitely useful.  

## Usage
```
./lazy_rclone.sh <server> <minimal/full>
```

The options are tailored to my needs, but can also be adjusted in the rclone config.
Personaly I use the following syntax: 
```
<date>_<server>_<minimal/full>.tar.bz2 
```
The the folder structure looks like this:
``` 
storage:<remote_root>/<backup_server>/<minimal/full>
``` 




## Author

* **Veit** - [gxf0](https://github.com/gxf0)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* feel free to copy and adjust the scripts for your need
* feel free to improve the scripts - maybe you could also notice me - haha
* feel free to contact me, if you have any question