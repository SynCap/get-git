Import-Module pswatch

# hmm...
 watch (pwd) -includeSubdirectories:$false | %{ @ $_ }


