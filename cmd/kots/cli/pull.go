package cli

import (
	"os"
	"path"

	"github.com/replicatedhq/kots/pkg/logger"
	"github.com/replicatedhq/kots/pkg/pull"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func PullCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:           "pull [upstream uri]",
		Short:         "",
		Long:          ``,
		SilenceUsage:  true,
		SilenceErrors: false,
		PreRun: func(cmd *cobra.Command, args []string) {
			viper.BindPFlags(cmd.Flags())
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			v := viper.GetViper()

			if len(args) == 0 {
				cmd.Help()
				os.Exit(1)
			}

			pullOptions := pull.PullOptions{
				HelmRepoURI: v.GetString("repo"),
				RootDir:     v.GetString("rootdir"),
				Overwrite:   v.GetBool("overwrite"),
				Namespace:   v.GetString("namespace"),
				Downstreams: v.GetStringSlice("downstream"),
			}
			if err := pull.Pull(args[0], pullOptions); err != nil {
				return err
			}

			log := logger.NewLogger()
			log.Initialize()
			log.Info("Kubernetes application files created in %q", v.GetString("rootdir"))
			if len(v.GetStringSlice("downstream")) == 0 {
				log.Info("To deploy, run kubectl -k %s", path.Join(v.GetString("rootdir"), "overlays", "midstream"))
			} else if len(v.GetStringSlice("downstream")) == 1 {
				log.Info("To deploy, run kubectl -k %s", path.Join(v.GetString("rootdir"), "overlays", "downstreams", v.GetStringSlice("downstream")[0]))
			} else {
				log.Info("To deploy, run kubectl -k from the downstream directory you would like to deploy")
			}

			return nil
		},
	}

	cmd.Flags().StringArray("set", []string{}, "values to pass to helm when running helm template")
	cmd.Flags().String("repo", "", "repo uri to use when downloading a helm chart")
	cmd.Flags().String("rootdir", homeDir(), "root directory that will be used to write the yaml to")
	cmd.Flags().Bool("overwrite", false, "if the upstream already exists, overwrite it")
	cmd.Flags().String("namespace", "default", "namespace to render the upstream to in the base")
	cmd.Flags().StringSlice("downstream", []string{}, "the list of any downstreams to create/update")

	return cmd
}