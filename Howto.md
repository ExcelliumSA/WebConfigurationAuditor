# How to add support for a new app server?

Follow these steps:

**Step 1:**

Add a new audit rules JSON file in this [folder](references) and follow this [naming convention](Architecture.md#rules-configuration-convention).

Ex: `apache.json`

**Step 2:**

Add the technology to this [enumeration](common/server_type.py) and use the uppercase name for the technology for the enum name of the new item.

Ex: `APACHE`

**Step 3:**

Add new dedicated parsing function in [this](parsing/parser.py) module using this name and signature: `def parse_config_data_[technology_lowercase](config_file_name, audit_rules)`

Ex: `parse_config_data_apache(config_file_name, audit_rules)`

:warning: This parsing function must return a `ConfigData` object.

**Step 4:**

Add a new condition to this block of the [main](main.py#L36) for the new technology added. 









