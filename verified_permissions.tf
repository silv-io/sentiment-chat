resource "aws_verifiedpermissions_policy_store" "main" {
  validation_settings {
    mode = "STRICT"
  }
}

resource "aws_verifiedpermissions_schema" "main" {
  policy_store_id = aws_verifiedpermissions_policy_store.main.id
  definition {
    value = <<EOT
{
    "sentiment-chat": {
        "entityTypes": {
            "User": {
                "memberOfTypes": [
                    "Application"
                ],
                "shape": {
                    "type": "Record",
                    "attributes": {
                        "name": {
                            "type": "String",
                            "required": true
                        }
                    }
                }
            },
            "Application": {}
        },
        "actions": {
            "connect": {
                "appliesTo": {
                    "principalTypes": [
                        "User"
                    ],
                    "resourceTypes": [
                        "Application"
                    ]
                }
            },
            "sendMessage": {
                "appliesTo": {
                    "principalTypes": [
                        "User"
                    ],
                    "resourceTypes": [
                        "Application"
                    ]
                }
            }
        }
    }
}
EOT
  }
}

resource "aws_verifiedpermissions_policy" "main" {
  policy_store_id = aws_verifiedpermissions_policy_store.main.id
  definition {
    static {
      statement = "permit(principal, action, resource);"
    }
  }
}
