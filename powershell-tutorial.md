# PowerShell Tutorial

## What do you need?

### PowerShell

Worth using PowerShell 7+ even if you're on Windows. Download options are found [here](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.1)

### Azure PowerShell Module

Install instructions can be found [here](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-6.3.0) but basically, we just run:

```powershell
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

### Azure CLI

Instructions to install the Azure CLI can be found [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)


## Fundamentals

You're probably already using PowerShell commands if you're in a Windows world and if you're on a Mac or Linux, lots of your usual commands will work in a similar way.

For example, `ls`, `cd`, `pwd`, `mv`, `man` are all aliases that map to PowerShell commands. If we use the command `Get-Alias ls` you'll see that `ls` is an alias for `Get-ChildItem`.

Now that we know this is a PowerShell command, we can look up the help on it by running `man ls` or in non-alias words `Get-Help Get-ChildItem`. This will show up the in-built help documentation for this command however you can also find this exact information on Microsoft's website by just Googling the command (This is my preference because you know it'll always be the latest documentation).

As PowerShell typically uses the `Verb-Noun` format for its commands and the documentation tends to have good examples, you can usually follow your nose on how to use a command.

Here's an example to recursively find all files that match `*.md` in a directory:

`Get-ChildItem -Recurse -Filter '*.md'`  

You'll notice above that there are some nice headings that give us some useful info. This is where things differ from bash in that everything in PowerShell is an object with many accessible properties. Each command output will usually be hiding away more properties than what's displayed on the screen. To look for these properties, you can use the command `Get-Member` which will take the output of whatever command you're passing along and display all the available properties e.g.

`Get-ChildItem -Recurse -Filter '*.md' | Get-Member`

We won't go into details about each of the MemberTypes but the fields you can easily access are of MemberType 'Property'. So how can we use these properties to do something useful?

What if we now want to know the full path of any matching `*.md` files and perhaps we want to know the creation time?

Firstly, let's save our original output into a variable. Here's the difference between Bash and PowerShell regarding assigning and using variables:

Bash Example

```bash
myvar="hello"
echo $myvar
```

PowerShell Example

```powershell
$myvar = "hello"
$myvar
```

So with this in mind, we can save our output into a variable, let's call it `$markdownFiles`:

`$markdownFiles = Get-ChildItem -Recurse -Filter '*.md'`

We've already seen how to look at all the available properties via `Get-Member` but what if we want to see absolutely everything our variable has to offer? We can do this by using the `Format-List *` command. `Format-List` outputs specific properties of a command and the wildcard basically says 'give me everything':

`$markdownFiles | Format-List *` or if we want to be cool and use an alias, `$markdownFiles | fl *`

The above command will output everything for each matching `*.md` file it finds which could get pretty hard to read if you've got a directory with loads of them in. If we just want to see one of the files, PowerShell has a great method of filtering the output with the `Select-Object` command. For the purpose of this demo, we'll use the `-First` property of Select-Object (Check the docs out online for more info) to select only the first match (It searches alphabetically by Name by default):

`$markdownFiles | Select-Object -First 1 | Format-List *`

Note on the above, we could also write `$markdownFiles | Format-List * | Select-Object -First 1` but it's best practice to filter as far left in the code as possible to reduce the number of operations the code needs to do.

Now that we've seen all the useful info we can get, let's say we want to grab the `FullName` and `CreationTime`. We can use the `Select-Object` command again but this time we can select a property or multiple properties to return:

`$markdownFiles | Select-Object -Property FullName,CreationTime`

You'll see from the above, we now have a new custom looking table with the properties we've specified. What if we want to sort by `CreationTime`? We can use the command `Sort-Object -Property CreationTime` e.g.

`$markdownFiles | Select-Object -Property FullName,CreationTime | Sort-Object -Property CreationTime`

What if we now want to only return files that were created within the last day? We can use the `Where-Object` command which selects objects from a collection based on their property values. As a basic demonstration of the command, here is how to return all items that have the name `README.md`:

`Get-ChildItem | Where-Object Name -eq 'README.md'`

Going back to our challenge of returning items created within the last day, we can do the following:

`$markdownFiles | Where-Object CreationTime -gt (Get-Date).AddDays(-1)`

You'll notice above that we've used another command `Get-Date` which returns the current date. The `.AddDays(-1)` section just takes a day off of the current date which is what we needed to compare our CreationTime to.

So, piecing it all together we get:

`$markdownFiles | Where-Object CreationTime -gt (Get-Date).AddDays(-1) | Select-Object -Property FullName,CreationTime | Sort-Object -Property CreationTime`

The above command goes through all of the files and folders in our variable, grabs all of the items that have a `CreationTime` greater than yesterday's date, selects the properties `FullName` and `CreationTime` to be displayed and then finally sorts the resulting list by `CreationTime`

Now let's move over to an Azure example using the Azure PowerShell module and then the Azure CLI. A task that came up recently was to add all Terraform Service Principals into an RBAC group for management permissions. We could do this manually via the Portal but it's super easy using PowerShell.

Firstly, for both the Azure PowerShell module and the Azure CLI, we'll need to be connected to Azure so let's do that for both of them first:

PowerShell
`Connect-AzAccount`

Azure CLI 
`az login`

Next up, we need to select the Subscription we're working in (Not really relevant for an AAD example as that is Tenant level but very important so you're not destroying stuff in the wrong Sub)

PowerShell
`Set-AzContext -Subscription '<SubId>'`

Azure CLI
`az account set --subscription '<SubId>'`

Now we want to grab all of our Terraform Service Principals. To find the commands for both azcli and AzPS a bit of Googling is required or you can trawl through the docs. One final option for PowerShell is to search for a command using `Get-Command -Module Az*` which will return every single command for the Az module of which you can then start to filter similar to what we did above.

`$servicePrincipals = Get-AzADServicePrincipal | Where-Object DisplayName -match '_TF$'`

Now we've got all of our Service Principals, we need to add them to the group of our choice. With a bit of Googling, you can see that the command to add a member to a group will look something like this (Docs [here](https://docs.microsoft.com/en-us/powershell/module/az.resources/add-azadgroupmember?view=azps-6.3.0)):

`Add-AzADGroupMember -MemberObjectId <Your Service Principal Object ID> -TargetGroupObjectId <Your Group Object ID>`

Looking at the output of our `$servicePrincipals` variable, we can see that `Id` is a property we can use to feed into the above command. Because there are more than one Service Principal in our variable, we will now need to do a simple `foreach` loop to iterate through each Service Principal:

```powershell
# Object ID for group 'mh-temp-ps-demo-group'
$groupObjectId = 'd5b06c01-e73f-45ab-933e-45003bcbca7c'

foreach ($sp in $servicePrincipals) {
    Add-AzADGroupMember -MemberObjectId $sp.Id -TargetGroupObjectId $groupObjectId
}
```

You'll notice in the above script we're using `.Id`. Whilst we could also do `$appReg | Select-Object -Property Id`, you can also use dot notation as above to access any of the properties available on your item.

Now we've added all of the SPs, let's remove them ready for the Azure CLI way:

```powershell
foreach ($sp in $servicePrincipals) {
    Remove-AzADGroupMember -MemberObjectId $sp.Id -GroupObjectId $groupObjectId
}
```

With the Azure CLI, you can do some fancy JMESPath query stuff to filter down into the data you want. This is outside of the scope of this tutorial but feel free to check out [this link](https://docs.microsoft.com/en-us/cli/azure/query-azure-cli) which covers some basic examples.

I personally find the query language quite difficult to use so I'll be showing how you can manipulate that data via PowerShell as per the Azure PowerShell Module commands.

Take this example:

`$servicePrincipals = az ad sp list --all`

You'll notice that if we pipe this output to `Get-Member` to see what properties we have available, we don't have anything useful. That's because by default, the output comes back as JSON and not in PowerShell objects. To get around this, we can use the `ConvertFrom-Json` command to convert things into our fluffy PowerShell object land:

`$servicePrincipals = az ad sp list --all | ConvertFrom-Json`

Now we can filter in the way we've done previously: 

`$servicePrincipals = az ad sp list --all | ConvertFrom-Json | Where-Object 'displayName' -match '_TF$'`

Now we can get into our loop as we've done with the Azure PowerShell Module way:

```powershell
$groupObjectId = 'd5b06c01-e73f-45ab-933e-45003bcbca7c'

foreach ($sp in $servicePrincipals) {
    az ad group member add --group $groupObjectId --member-id $sp.objectId
}
```
