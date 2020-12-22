# Buildbot script for CircleCI
# coded by bruh™ aka Exynos-nigg

MANIFEST_LINK=https://gitlab.com/OrangeFox/Manifest.git
BRANCH=fox_9.0
DEVICE_CODENAME=dream2lte
GITHUB_USER=Exynos-nigg
GITHUB_EMAIL=vsht700@gmail.com
WORK_DIR=$(pwd)/Ofox-${DEVICE_CODENAME}
JOBS=$(nproc)
SPACE=$(df -h)
RAM=$(free mem -h)

# Check CI specs!
echo "Checking specs!"
echo "CPU cores = ${JOBS}"
echo "Space available = ${SPACE}"
echo "RAM available = ${RAM}"
sleep 25 

# Set up git!
echo ""
echo "Setting up git!"
git config --global user.name ${GITHUB_USER}
git config --global user.email ${GITHUB_EMAIL}
git config --global color.ui true
echo "Done!"

# randomize and fix sync thread number, according to available cpu thread count
SYNC_THREAD=$(grep -c ^processor /proc/cpuinfo)          # Default CPU Thread Count
if [[ $(echo ${JOBS}) -le 2 ]]; then SYNC_THREAD=$(shuf -i 5-7 -n 1)        # If CPU Thread >= 2, Sync Thread 5~7
elif [[ $(echo ${JOBS}) -le 8 ]]; then SYNC_THREAD=$(shuf -i 12-16 -n 1)    # If CPU Thread >= 8, Sync Thread 12~16
elif [[ $(echo ${JOBS}) -le 36 ]]; then SYNC_THREAD=$(shuf -i 30-36 -n 1)   # If CPU Thread >= 36, Sync Thread 30~36
fi

# make directories
echo ""
echo "Setting work directories!"
mkdir ${WORK_DIR} && cd ${WORK_DIR}

# set up rom repo
echo ""
echo "Syncing rom repo!"
repo init --depth=1 -u ${MANIFEST_LINK} -b ${BRANCH}
repo sync -j${SYNC_THREAD} --force-sync

# clone device sources
echo ""
echo "Cloning device sources!"

# Device tree
git clone -b android-9.0 https://github.com/Exynos-nigg/OrangeFox_device_samsung_dream2lte device/samsung/dream2lte

# Kernel source 
git clone -b 9 https://github.com/corsicanu/android_kernel_samsung_universal8895 kernel/samsung/universal8895

# extra dependencie for building dtbo
git clone -b lineage-16.0 https://github.com/LineageOS/android_hardware_samsung.git hardware/samsung

# Start building!
echo ""
echo "Starting build!"
. build/envsetup.sh && lunch omni_${DEVICE_CODENAME}-eng && mka recoveryimage -j${JOBS}

# copy final product to another folder
echo ""
echo "Copying final product to another dir!"
mkdir ~/output
cp ${WORK_DIR}/out/target/product/*/*.zip ~/output/
cp ${WORK_DIR}/out/target/product/*/recovery.img ~/output/

echo ""
echo "Done baking!"
echo "Build will be uploaded in the artifacts section in CircleCI! =) "
echo ""
