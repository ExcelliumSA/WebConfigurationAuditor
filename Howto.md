# How to add support for a new app server?

Follow these steps.

**Step 1:**

Add a new audit rules JSON file in this [folder](references) and follow this [naming convention](Architecture.md#rules-configuration-convention).

Ex: `apache.json`

**Step 2:**

Add the technology to this [enumeration](common/server_type.py) and use the uppercase name for the technology for the enum name of the new item (continue the integer sequence for the value of the new item).

Ex: `APACHE`

**Step 3:**

Add new dedicated parsing function in [this](parsing/parser.py) module using this name and signature: `def parse_config_data_[technology_lowercase](config_file_name, audit_rules)`

Ex: `parse_config_data_apache(config_file_name, audit_rules)`

:warning: This parsing function must return a `ConfigData` object.

**Step 4:**

Add a new condition to this block of the [main](main.py#L36) for the new technology added. 

# How to add a new audit rule?

## File information for the different supported technology

### Apache

- **Reference audit rules**: Audit rules are defined in this [file](references/apache.json).
- **Triggering test config**: Test configuration snippet that **trigger all the rules** are defined in this [file](tests/data/apache_test_config_all_issues.conf).
- **No triggering test config**: Test configuration snippet that **trigger NO rules** are defined in this [file](tests/data/apache_test_config_no_issue.conf).

### Tomcat

TODO

### IIS

TODO

## Procedure

Follow these steps.

**Step 1:**

Add a new rule block in the **reference audit rules** following this [naming convention](Architecture.md#rules-configuration-convention).

**Step 2:**

Add a configuraton snippet in the **triggering test config** that **will trigger** the rule added.

:warning: Add comment above the snippet in order to specify the CIS point to which the rule refer.

:warning: Perform this for all regex expression added for a rule!

**Step 3:**

Add a configuraton snippet in the **no triggering test config** that **will NOT trigger** the rule added.

:warning: Add comment above the snippet in order to specify the CIS point to which the rule refer.

:warning: Perform this for all regex expression added for a rule!

**Step 4:**

Run the following command line to ensure that your configuration is valid:

```bash
$ pytest
```

:information_source: If all unit tests pass then your new rule is correctly added.









