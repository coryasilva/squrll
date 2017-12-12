component accessors='false' {

  property name="settings" inject="coldbox:modulesettings:squrll" getter="false" setter="false";

  public Service function init() {
    return this;
  }

}