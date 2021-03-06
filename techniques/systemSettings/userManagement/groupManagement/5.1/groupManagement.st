#####################################################################################
# Copyright 2011-2017 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

##########################################################################
# Group management Technique                                             #
#                                                                        #
# Objective : Apply group policies on the target host                    #
##########################################################################


bundle agent check_usergroup_grp_parameters_RudderUniqueID {

	vars:
		&USERGROUP_GROUP_NAME:{name |"usergroup_group_name[&i&]" string => "&name&";
}&

        &USERGROUP_GROUP_CREATE:{create |"usergroup_group_create[&i&]" string => "&create&";
}&

        &USERGROUP_GROUP_SET_GID:{setgid |"usergroup_group_set_gid[&i&]" string => "&setgid&";
}&

        &USERGROUP_GROUP_GID:{gid |"usergroup_group_gid[&i&]" string => "&gid&";
}&

        &USERGROUP_GROUP_ENFORCE_CONTENT:{enforce_content |"usergroup_group_enforce_content[&i&]" string => "&enforce_content&";
}&

        &USERGROUP_GROUP_CONTENT:{content |"usergroup_group_content[&i&]" string => "&content&";
}&

        &USERGROUP_GROUP_POLICY:{policy |"usergroup_group_policy[&i&]" string => "&policy&";
}&

        &TRACKINGKEY:{directiveId |"usergroup_group_directive_id[&i&]" string => "&directiveId&";
}&

		"usergroup_group_index" slist => getindices("usergroup_group_name");

	methods:

      "any"
        usebundle => check_usergroup_group_parameters_grouphandle_RudderUniqueID("${usergroup_group_name[${usergroup_group_index}]}", "${usergroup_group_create[${usergroup_group_index}]}", "${usergroup_group_set_gid[${usergroup_group_index}]}", "${usergroup_group_gid[${usergroup_group_index}]}","${usergroup_group_enforce_content[${usergroup_group_index}]}", "${usergroup_group_content[${usergroup_group_index}]}", "${usergroup_group_index}", "${usergroup_group_directive_id[${usergroup_group_index}]}");

}

bundle agent check_usergroup_group_parameters_grouphandle_RudderUniqueID(name, create, setgid, gid, enforce_content, content, index, directiveId) {

    vars:

        "userlist" slist => splitstring("${content}",",","16");


    classes:

        "groupmanagement_group_${index}_absent"          not => groupexists("${name}");
        "groupmanagement_group_${index}_create"          expression => strcmp("${create}", "true");
        "groupmanagement_group_${index}_setgid"          expression => strcmp("${setgid}", "true");
        "groupmanagement_group_${index}_enforce_content" expression => strcmp("${enforce_content}", "true");

    any::
      "pass3" expression => "pass2";
      "pass2" expression => "pass1";
      "pass1" expression => "any";

    files:

        # Enforce group content on if groupmanagement_group_${index}_enforce_content is set
        "/etc/group"
            edit_line     => groups_file_set_RudderUniqueID("${name}", "@(check_usergroup_group_parameters_grouphandle_RudderUniqueID.userlist)"),
            edit_defaults => noempty_backup,
            classes       => rudder_common_classes("groupmanagement_group_add_${index}_RudderUniqueID"),
            ifvarclass    => "groupmanagement_group_${index}_enforce_content.(!groupmanagement_group_${index}_absent|groupmanagement_group_add_${index}_RudderUniqueID_repaired)",
            comment       => "Set users on the group ${name} only if the group is already present";

        # Append group content on if groupmanagement_group_${index}_enforce_content is not set
        "/etc/group"
            edit_line     => append_user_field("${name}", "4", "@(check_usergroup_group_parameters_grouphandle_RudderUniqueID.userlist)"),
            edit_defaults => noempty_backup,
            classes       => rudder_common_classes("groupmanagement_group_add_${index}_RudderUniqueID"),
            ifvarclass    => "!groupmanagement_group_${index}_enforce_content.(!groupmanagement_group_${index}_absent|groupmanagement_group_add_${index}_RudderUniqueID_repaired)",
            comment       => "Append users on the group ${name} only if the group is already present";

        # Enforce GID if setgid has been set
        "/etc/group"
            create     => "false",
            edit_line  => set_user_field("${name}", 3, "${gid}"),
            classes    => rudder_common_classes("groupmanagement_group_gid_${index}_RudderUniqueID"),
            ifvarclass => "!groupmanagement_group_${index}_absent.groupmanagement_group_${index}_setgid";



  methods:

    pass3.cfengine::

      "any" usebundle => rudder_common_report("groupManagement", "result_success", "${directiveId}", "Groups", "${name}", "The group ${name} is already present and compliant with the policy"),
                ifvarclass => "groupmanagement_group_add_${index}_RudderUniqueID_kept.!(groupmanagement_group_add_${index}_RudderUniqueID_repaired|groupmanagement_group_add_${index}_RudderUniqueID_error)";

      "any" usebundle => rudder_common_report("groupManagement", "result_repaired", "${directiveId}", "Groups", "${name}", "The group ${name} has been updated"),
                ifvarclass => "groupmanagement_group_add_${index}_RudderUniqueID_repaired.!groupmanagement_group_add_${index}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report("groupManagement", "result_error", "${directiveId}", "Groups", "${name}", "The group ${name} could not be created or updated"),
                ifvarclass => "groupmanagement_group_add_${index}_RudderUniqueID_error";

      "any" usebundle => rudder_common_report("groupManagement", "result_success", "${directiveId}", "Groups", "${name}", "The group ${name} is not present and not set to be created"),
                ifvarclass => "groupmanagement_group_${index}_absent.!groupmanagement_group_${index}_create";

       #Group enforce GID
      "any" usebundle => rudder_common_reports_generic("groupManagement", "groupmanagement_group_gid_${index}_RudderUniqueID", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} gid set it ${gid}"),
                ifvarclass => "!groupmanagement_group_${index}_absent.groupmanagement_group_${index}_setgid";

      "any" usebundle => rudder_common_report("groupManagement", "result_na", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} is not present"),
                ifvarclass => "groupmanagement_group_${index}_absent";

      "any" usebundle => rudder_common_report("groupManagement", "result_na", "${directiveId}", "Group enforce GID", "${name}", "The group ${name} is not set to have its gid set"),
                ifvarclass => "!groupmanagement_group_${index}_absent.!groupmanagement_group_${index}_setgid";




    commands:

      !aix::
        "/usr/sbin/groupadd"
            args => "-f \"${name}\"",
            classes => if_else("groupmanagement_group_add_${index}_RudderUniqueID_repaired", "groupmanagement_group_add_${index}_RudderUniqueID_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.!groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} if it doesn't exists";

        "/usr/sbin/groupadd"
            args => "-f \"${name}\" -g \"${gid}\"",
            classes => if_else("groupmanagement_group_add_${index}_RudderUniqueID_repaired", "groupmanagement_group_add_${index}_RudderUniqueID_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} with GID ${gid} if it doesn't exists";

      aix::
        "/usr/bin/mkgroup"
            args => "${name}",
            classes => if_else("groupmanagement_group_add_${index}_RudderUniqueID_repaired", "groupmanagement_group_add_${index}_RudderUniqueID_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.!groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} if it doesn't exists";

        "/usr/bin/mkgroup"
            args => "id=${gid} ${name}",
            classes => if_else("groupmanagement_group_add_${index}_RudderUniqueID_repaired", "groupmanagement_group_add_${index}_RudderUniqueID_error"),
            ifvarclass => "groupmanagement_group_${index}_absent.groupmanagement_group_${index}_create.groupmanagement_group_${index}_setgid",
            comment => "Add the group ${name} with GID ${gid} if it doesn't exists";

}

bundle edit_line groups_file_set_RudderUniqueID(group,userlist)
{

vars:

	"finalgroup" string => join(",","userlist");

field_edits:

	"${group}:.*"

	# Set field of the file to parameter
	# /etc/group entry is: groupname:x:gid:users
	edit_field => col(":","4","${finalgroup}","set");

}
