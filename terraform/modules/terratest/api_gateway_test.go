package terratest

import (
  "testing"
  terratest_aws "github.com/gruntwork-io/terratest/modules/aws"
  "github.com/stretchr/testify/require"
)

// Smoke: Validar que la REST API existe (naming por tag/var)
func TestApiGatewayExists(t *testing.T) {
  region := "us-east-1"
  apis := terratest_aws.GetAllRestApis(t, region)
  require.GreaterOrEqual(t, len(apis), 1, "No se encontraron APIs en la cuenta/región")
}


