#!/bin/bash
# menu_plugin
PLUGIN_NAME="Chromebook Serialization Utility"
PLUGIN_FUNCTION="Run the Chromebook Serialization Utility"
PLUGIN_DESCRIPTION="Allows you to change your Chromebook's serial number and other VPD (vital product data)"
PLUGIN_AUTHOR="kubisnax, rainestorme"
PLUGIN_VERSION=1

doas() {
    ssh -t -p 1337 -i /rootkey -oStrictHostKeyChecking=no root@127.0.0.1 "$@"
}

pushd /tmp
    echo "WARNING: THIS SCRIPT WILL IRREVERSIBLY MODIFY YOUR CHROMEBOOK AND WILL ABSOLUTELY VIOLATE YOUR DISTRICT'S RULES!"
    echo "IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH OF THIS SOFTWARE AND THE RELATED DOCUMENTATION FILES (the \"Software\") OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
    echo "If you do not want to continue, press Ctrl+C now. Otherwise, type 'I acknowledge' at the next prompt."
    sleep 5
    read -p ' > ' acknowledgement
    if [ "$acknowledgement" == "I acknowledge" ]; then
        echo "This script will set gbb_flags to 0x0, dump vpd logs, delete mlb_serial_number and delete stable_device_secret_DO_NOT_SHARE, delete Product_S/N then shutdown the system."
        read -p "This is your last chance. Ask yourself: Are you sure - completely sure - that you want to do this? If not, press Ctrl+C in the next 5 seconds." 
        sleep 5
        curl -LOk https://raw.githubusercontent.com/kubisnax/chromebook_serialization_tool/master/cst.sh
        doas "pushd /tmp
        bash cst.sh"
    else
        echo "License not acknowledged, exiting..."
        exit
    fi
popd
