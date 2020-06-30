$data = @()

$mbxs = get-mailbox -ResultSize unlimited -filter {recipienttypedetails -eq "sharedmailbox"}

foreach ($mb in $mbxs)

{

    $dataobject = new-object psobject

    $stats = Get-MailboxStatistics -Identity $mb.UserPrincipalName

    $dataobject | add-member -NotePropertyValue $MB.userprincipalname -NotePropertyName UserPrincipalName

    $dataobject | add-member -NotePropertyValue $mb.displayname -NotePropertyName Displayname

    $dataobject | add-member -NotePropertyValue $stats.totalitemsize -NotePropertyName Totalsize

    switch -Wildcard ($stats.totalitemsize.value)

    {

        "*GB*"

        {

            $totalitemsize = $stats.TotalItemSize.Value -replace " GB*"

            $totalsize = $totalitemsize.Split(" ")[0]

            if ( [math]::Round($totalsize, 3) -gt 48)

            {

                $dataobject | add-member -NotePropertyValue "MAILBOX LIMIT IS REACHED" -NotePropertyName "Mailbox Limit"

            }

            else

            {

                $dataobject | add-member -NotePropertyValue "Mailbox is ok" -NotePropertyName "Mailbox Limit"

            }

        }

        "*MB*"

        {

            $dataobject | add-member -NotePropertyValue "Mailbox is ok" -NotePropertyName "Mailbox Limit"

        }

        "*KB*"

        {

            $dataobject | add-member -NotePropertyValue "Mailbox is ok" -NotePropertyName "Mailbox Limit"

        }

    }

    $data += $dataobject

}

$data | export-csv C:\temp\totalitemsize_SMBX-V2.csv -NoTypeInformation