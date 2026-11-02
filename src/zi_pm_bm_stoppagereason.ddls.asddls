@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'BM - Stoppage Reasons (Cascading Dropdown)'

define view entity ZI_PM_BM_StoppageReason
  as select from zpm_stop_config as cfg

  inner join qpcd as basic_cat
    on basic_cat.katalogart = 'B'
   and basic_cat.codegruppe = cfg.basic_code_grp
   and basic_cat.code       = cfg.basic_code
   
    left outer join qpct as basic_cat_text
    on basic_cat_text.katalogart = 'B'
   and basic_cat_text.codegruppe = basic_cat.codegruppe
   and basic_cat_text.code       = basic_cat.code
 and basic_cat_text.sprache    = $session.system_language

  left outer join qpcd as detail_cat
    on detail_cat.katalogart = 'C'
   and detail_cat.codegruppe = cfg.detail_code_grp
   and detail_cat.code       = cfg.detail_code
   
    left outer join qpct as detail_cat_text
    on detail_cat_text.katalogart = 'C'    
   and detail_cat_text.codegruppe = detail_cat.codegruppe
   and detail_cat_text.code       = detail_cat.code 
 and detail_cat_text.sprache    = $session.system_language
   
{
  key cfg.plant             as Plant,
  key cfg.wc_category       as WCCategory,
  key cfg.basic_code_grp    as BasicCodeGroup,
  @ObjectModel.text.element: ['BasicStoppageText']
  @UI.textArrangement: #TEXT_LAST
  key cfg.basic_code        as BasicCode,
  key cfg.detail_code_grp   as DetailCodeGroup,
    @ObjectModel.text.element: ['DetailStoppageText']
  @UI.textArrangement: #TEXT_LAST
  key cfg.detail_code       as DetailCode,

      @Semantics.text: true
      basic_cat_text.kurztext  as BasicStoppageText,
      @Semantics.text: true
      detail_cat_text.kurztext as DetailStoppageText,
      cfg.active               as Active
}
where cfg.active = 'X'