#!/bin/bash

###
### VARIABLES
###

developer_id="Developer ID Application: XXX (xxx)"
developer_id_username="xxx@xxx.com"

### NOTE
# To notarize the DMG you need an app-specific password created for the developer id set in developer_id_username.
# Create one at appleid.apple.com
# Create a keychain item with the same name as the developer id set in developer_id_username and set the app specific password as the password.
# This will allow the xcrun binary to use this account automatically.

###
### FUNCTIONS
###

function pfc_error_exit {
	printf "%s\n" "ERROR: ${1}" 1>&2
	exit 1
}

###
### MAIN SCRIPT
###

pfc_path="${1}"

printf "%s\n" "Gathering information about application at: ${pfc_path}"

# Get the basename of the passed path
pfc_basename=$( basename "${pfc_path}" )
if [[ ${pfc_basename} != ProfileCreator.app ]]; then
	pfc_error_exit "Usage: $( basename "${0}" ) <path to ProfileCreator.app>"
fi
pfc_name="${pfc_basename%.*}"
pfc_info_plist="${pfc_path}/Contents/Info.plist"

# Get the version of ProfileCreator
pfc_version=$( /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${pfc_info_plist}" 2>/dev/null )
if ! [[ ${pfc_version} =~ ^[0-9.]+$ ]]; then
	pfc_error_exit "Unexpected CFBundleShortVersionString: ${pfc_version}"
fi
printf "%s\n" "Version: ${pfc_version}"

# Get the build of ProfileCreator
pfc_build=$( /usr/libexec/PlistBuddy -c "Print CFBundleVersion" 2>/dev/null "${pfc_info_plist}" )
if ! [[ ${pfc_build} =~ ^[0-9.]+$ ]]; then
	pfc_error_exit "Unexpected CFBundleVersion: ${pfc_version}"
fi
printf "%s\n" "Build: ${pfc_build}"

pfc_bundle_id=$( /usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" 2>/dev/null "${pfc_info_plist}" )
if ! [[ ${pfc_bundle_id} =~ ^[a-zA-Z.]+$ ]] || ! [[ ${pfc_bundle_id} =~ "ProfileCreator" ]]; then
	pfc_error_exit "Unexpected CFBundleIdentifier: ${pfc_version}"
fi
printf "%s\n" "Bundle ID: ${pfc_bundle_id}"

# Create the filename for the deployment packages
pfc_git_tag="v${pfc_version}"
pfc_deploy_filename="${pfc_name}_${pfc_git_tag}-${pfc_build}-beta"

# Path to dmg
pfc_dmg_path="/tmp/${pfc_deploy_filename}"
pfc_dmg_path_tmp="${pfc_dmg_path}_tmp"

# Create an empty base dmg
printf "%s\n" "Creating Empty DMG"
hdiutil_output=$( hdiutil create -volname "ProfileCreator" -size 30MB -fs HFS+ -ov -type SPARSEBUNDLE -attach -plist "${pfc_dmg_path_tmp}" )

# Get and verify the path to the empty dmg
pfc_dmg_path_tmp_mnt=$( xpath '/plist/dict/key[.="system-entities"]/following-sibling::array/dict/key[.="mount-point"]/following-sibling::*[1]/text()' 2>/dev/null <<< "${hdiutil_output}" )

# Copy ProfileCreator to dmg
printf "%s\n" "Copy app to DMG"
if ! cp -R "${pfc_path}" "${pfc_dmg_path_tmp_mnt}/${pfc_basename}"; then
	pfc_error_exit "Failed to copy app to dmg"
fi

# Set the window layout of the dmg
printf "%s\n" "Modify DMG View Properties"
echo '
   tell application "Finder"
     tell disk "'${pfc_name}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 885, 430}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 80
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "'${pfc_basename}'" of container window to {100, 100}
           set position of item "Applications" of container window to {375, 100}
           update without registering applications
           delay 5
           close
     end tell
   end tell
' | osascript

# Set correct permissions
printf "%s\n" "Modify DMG Permissions"
if ! chmod -Rf go-w "${pfc_dmg_path_tmp_mnt}"; then
	pfc_error_exit "Failed to update permissions of the dmg"
fi
sync
sync

# Detach the temporary dmg
if ! hdiutil detach "${pfc_dmg_path_tmp_mnt}" -quiet; then
	pfc_error_exit "Failed to detach the dmg"
fi

# Verify the target dmg does not exist
pfc_dmg_path_full="${pfc_dmg_path}.dmg"
if [[ -f ${pfc_dmg_path_full} ]]; then
	if ! rm "${pfc_dmg_path_full}"; then
		pfc_error_exit "Failed to remove an existing dmg at: ${pfc_dmg_path_full}"
	fi
fi

# Convert the dmg to read only
printf "%s\n" "Convert DMG To Read Only Format"
if ! hdiutil convert "${pfc_dmg_path_tmp}.sparsebundle" -quiet -format UDZO -imagekey zlib-level=9 -o "${pfc_dmg_path}"; then
	pfc_error_exit "Failed to convert the dmg"
fi

# Remove the temporary dmg
if ! rm -rf "${pfc_dmg_path_tmp}.sparsebundle"; then
	pfc_error_exit "Failed to remove the temporary dmg"
fi

# Create Copy the dmg to the desktop
pfc_deploy_directory="${HOME}/Desktop/ProfileCreatorDeployment"
if ! [[ -d ${pfc_deploy_directory} ]]; then
	if ! mkdir "${pfc_deploy_directory}"; then
		pfc_error_exit "Failed to create the deploy directory at: ${pfc_deploy_directory}"
	fi
else
	rm -f "${pfc_deploy_directory}/*"
fi

# Move the dmg to the deploy directory
printf "%s\n" "Move DMG To Deployment Directory at: ${pfc_deploy_directory}"
if ! mv "${pfc_dmg_path_full}" "${pfc_deploy_directory}"; then
	pfc_error_exit "Failed to move the dmg to the deploy directory"
fi
pfc_dmg_path="${pfc_deploy_directory}/$( basename ${pfc_dmg_path} ).dmg"

# Make a copy of the dmg in the deploy directory
pfc_dmg_path_unsigned="${pfc_dmg_path%.*}_unsigned.dmg"
if ! cp "${pfc_dmg_path}" "${pfc_dmg_path_unsigned}"; then
	pfc_error_exit "Failed to make a copy of the dmg in the deploy directory"
fi

# Sign the dmg
printf "%s\n" "Codesign DMG"
if ! codesign --force --sign "${developer_id}" "${pfc_dmg_path}"; then
	pfc_error_exit "Failed to codesing the dmg in the deploy directory"
fi

# Send the dmg for notarization
printf "%s\n" "Uploading DMG for notarization"
notarization_app_info=$( xcrun altool --notarize-app --primary-bundle-id "${pfc_bundle_id}" --username "${developer_id_username}" --password "@keychain:${developer_id_username}" --type osx --file "${pfc_dmg_path}" 2>&1 )
notarization_uuid=$( awk '/RequestUUID/ { print $NF }' <<< "${notarization_app_info}" )
printf "%s\n" "DMG Notarization UUID: ${notarization_uuid}"

notarization_status="unknown"

# Wait until notarization has finished
while [[ ${notarization_status} != "success" ]]; do
	
	sleep 15
	
	printf "%s" "Checking Notarization Status: "
	notarization_info=$( xcrun altool --notarization-info "${notarization_uuid}" --username "${developer_id_username}" --password "@keychain:${developer_id_username}" 2>&1 )
	notarization_status=$( awk -F": " '/Status:/ { print $NF }' <<< "${notarization_info}" )
	printf "%s\n" "${notarization_status}"
done

# Staple the notarized dmg
printf "%s\n" "Staple Notarization Ticket to DMG"
staple_output=$( xcrun stapler staple "${pfc_dmg_path}" )

# Verify the stapled dmg
printf "%s\n" "Verifying Stapled DMG"
if ! xcrun stapler validate -q "${pfc_dmg_path}"; then
	pfc_error_exit "Failed to verify the stapled dmg"
fi

# Reveal the completed dmg in Finder
open -R "${pfc_dmg_path}"

pfc_dmg_basename=$( basename "${pfc_dmg_path}" )
pfc_dmg_bytes=$( stat -f%z "${pfc_dmg_path}" )
current_date=$( date "+%a, %d %b %Y %T %z" )

# Print a basic appcast item xml
cat << EOF
<item>
    <title>Version ${pfc_version}</title>
    <pubDate>${current_date}</pubDate>
    <sparkle:minimumSystemVersion>10.12</sparkle:minimumSystemVersion>
    <sparkle:releaseNotesLink>https://profilecreator.github.io/releasenotes/${pfc_git_tag}.html</sparkle:releaseNotesLink>
    <enclosure url="https://github.com/ProfileCreator/ProfileCreator/releases/download/${pfc_git_tag}/${pfc_dmg_basename}" sparkle:shortVersionString="${pfc_version}" sparkle:version="${pfc_build}" length="${pfc_dmg_bytes}" type="application/octet-stream"/>
</item>
EOF
