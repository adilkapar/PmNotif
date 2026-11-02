@EndUserText.label: 'ZI_User_Default_Plant'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_User_Default_Plant
  as select from usr05
{
  key bname as UserName,
      parva as Plant
}
where
      bname = $session.user
  and parid = 'WRK' // 'WRK' is the standard SU01 Parameter ID for Plant