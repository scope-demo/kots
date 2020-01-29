package v1beta1

import (
	"log"
	"os"
	"testing"

	"go.undefinedlabs.com/scopeagent"
	"go.undefinedlabs.com/scopeagent/agent"
	"go.undefinedlabs.com/scopeagent/instrumentation/nethttp"
)

func TestMain(m *testing.M) {
	log.SetFlags(log.LstdFlags | log.Lmicroseconds | log.Llongfile)
	nethttp.PatchHttpDefaultClient()
	os.Exit(scopeagent.Run(m, agent.WithSetGlobalTracer()))
}
