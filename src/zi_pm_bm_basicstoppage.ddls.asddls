@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'BM - Basic Stoppage Codes'

define view entity ZI_PM_BM_BasicStoppage
  as select distinct from zpm_stop_config as cfg

  left outer join qpct as basic_cat_text
    on basic_cat_text.katalogart = 'B'
   and basic_cat_text.codegruppe = cfg.basic_code_grp
   and basic_cat_text.code       = cfg.basic_code
   and basic_cat_text.sprache    = $session.system_language

{
  key cfg.plant           as Plant,
  key cfg.basic_code_grp  as BasicCodeGroup,
  @ObjectModel.text.element: ['BasicStoppageText']
  @UI.textArrangement: #TEXT_LAST
  key cfg.basic_code      as BasicCode,

      @Semantics.text: true
      basic_cat_text.kurztext as BasicStoppageText
}
where cfg.active = 'X'