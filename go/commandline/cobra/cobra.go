package main

import (
	"fmt"

	"github.com/spf13/cobra"
)


func main(){
	cmd := cobra.Command{
		Use: "cobra",
		Short: "this is a cobra demo",
		Run: func(cmd *cobra.Command, args []string){
			fmt.Println("good! you run a cobra command!")
		},
	}
	var newLine *bool
	subCmd := cobra.Command{
		Use: "echo",
		Short: "echo your input",
		Run: func(cmd *cobra.Command, args []string){
			for _, arg := range args {
				if newLine != nil && *newLine{
					fmt.Println(arg)
				}else{
					fmt.Printf("%s ", arg)
				}
			}
			if newLine == nil || ! *newLine{
				fmt.Println()
			}
		},
	}
	newLine = subCmd.Flags().BoolP("newline", "n", false, "display one word per line")

	cmd.AddCommand(&subCmd)
	cmd.Execute()
}