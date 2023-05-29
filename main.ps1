<#
Author = me
Date = 20/04/2023
Version = 1.4
1.4 = Added If{} / Else{} block for mapping personal share in user session
1.3 = Add Try{} / Catch{} block to create personal share and add rights
1.2 = Add Try{} / Catch{} blocks to create user in AD 
      and added to the security group
1.1 = Declaration of variables
1.0 = First version

Description = Script for creating users in AD, adding them to a security group and creating a personal share
#>

Import-Module NTFSSecurity #Import of the `NTFSSecurity` module for NTFS rights

#Declaration of variables to retrieve user information
$surname = Read-host "Donnez le nom"
$givenname = Read-host "Donnez le prénom"

#Choice of user groups
Write-Host " 
1 - Stagiaire
2 - RH
3 - Commercial
4 - Direction
5 - Informatique
6 - Finance
7 - Logistique
8 - Marketing
 " 

#Declaration of variables for user creation on AD
$group = Read-Host "Groupe de l'utilisateur"
$GG = "GG_" + $group
$password = ConvertTo-SecureString -AsPlainText "@Password1234" -Force
$mail = $givenname[0] + "." + $surname + "@LAB.LOC" 

#Variable declaration for personal sharing
$share = $givenname[0] + "." + $surname 

 
#Block for user creation in AD
Try {

New-ADUser -Name ($givenname + " " + $surname) `
           -GivenName ($givenname) `
           -Surname ($surname) `
           -SamAccountName ($givenname[0] + "." + $surname) `
           -UserPrincipalName ($givenname[0] + "." + $surname + "@LAB.LOC") `
           -AccountPassword $password `
           -ChangePasswordAtLogon $true `
           -Enable $true `
           -Path "OU= $group,DC=LAB,DC=LOC"`
           -EmailAddress $mail `
           
         
          
Write-Host "L'utilisateur a été ajouté dans l'Active Directory" -ForegroundColor "Green"

} 

#Error message in case of failure
Catch {
         
Write-Host " Une erreur est survenue lors de l'ajout de l'utilisateur dans l'Active Directory" -ForegroundColor "red"

} 
           
#Block for importing the user into a security group          
Try {

Add-ADGroupMember -Identity $GG -Members ($givenname[0] + "." + $surname)

Write-Host "L'utilisateur a été ajouté dans le groupe $group" -ForegroundColor "Green"

} 

#Error message in case of failure 
Catch {

Write-Host " Une erreur est survenue lors de l'ajout de l'utilisateur dans le groupe $group" -ForegroundColor "red"


} 

#Block for creating personal share and creating SMB and NTFS rights
Try {

New-Item -ItemType Directory -Path ("E:\Partages personnels\" + $share )

New-SmbShare -Name ($share + "$") -Path ("E:\Partages personnels\" + $share) -FullAccess "Administrateurs", $share

Add-NTFSAccess -Path ("E:\Partages personnels\" + $share) -Account $share -AccessRights Modify

Get-Item ("E:\Partages personnels\" + $share) | Disable-NTFSAccessInheritance

Set-NTFSOwner -Path ("E:\Partages personnels\" + $share) -Account $share

Remove-NTFSAccess –Path ("E:\Partages personnels\" + $share)  –Account "Utilisateurs" -AccessRights FullControl

Write-Host "Le dossier personnel a bien été créé et partagé " -ForegroundColor Green


}   

#Error message in case of failure
Catch {

Write-Host "Une erreur est survenue lors de la création ou du partage du dossier personnel" -ForegroundColor "red"

}          

#Variable declaration for the personal share path
$Map = "\\srv-ad\" + "$share" + "$" 

#Block for mapping personal share to user session
if(Test-Path $map){
   
   try {
   
    set-aduser $share -HomeDrive "P:" -HomeDirectory $map

    Write-Host "Dossier personnel correctement mapper" -ForegroundColor Green
    
   }catch{
    
    Write-Host "Une erreur est survenue" -ForegroundColor "red"
    
    }
    
}else{

Write-Host "Partage introuvable" -ForegroundColor "red"

}





