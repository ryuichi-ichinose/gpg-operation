# setup .env  
    export GPG_KEY_NAME="yourname"
    export GPG_KEY_EMAIL="your mail "
    export GPG_RAMDISK_DIR="/dev/shm/gpg_workspace"

# install dependencies
make install-deps

# generate primary-key and back up USB
# get your finger print (export GPG_FPR="your finger print")
make generate-primary-key USB ="your usb path"

# import gpg primary key(and sub keys) from usb to GPG_RAMDISK_DIR
make import-keys USB = "your usb path"

# add subkeys by primarykey you import 
make add-subkeys USB = "your usb path"

# setup your yubikey Ed25519
make setup-yubikey
#  move sbukey to your yubikey
make move-subkeys-to-card 

# clean up rmdisk
make cleanup