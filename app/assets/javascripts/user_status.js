(function($, undefined) {
   var COOKIE_NAME = 'psd-samples-extraction-login';
   
    function UserStatus(node, params) {
     this.node = $(node);
     this.usernameNode = $(params.usernameSelector, this.node);
     this.fullNameNode = $(params.fullNameSelector, this.node);     
     this.controlLoggedOut = $(params.logoutSelector, this.node);
     this.controlLoggedIn = $(params.loginSelector, this.node);
     this.changeLoginNode = $(params.changeLoginSelector, this.node);

     this.attachHandlers();
     this.initialize(params);
   };

    var proto = UserStatus.prototype;

    proto.initialize = function(params) {
	if (this.isLogged()) {
	    this.controlLoggedOut.hide();	    	    
	    this.updateLogin(this.getCookie());
	    this.controlLoggedIn.show();	    
	} else {
	    this.controlLoggedIn.hide();
	    this.controlLoggedOut.show();	    	    	    
	}
    };
   
   proto.login = function(data) {
     $(document.body).toggleClass('logged-in', true);
     if (this.isLogged()) {
       this.logout();
        }
     this.updateLogin(data);
     this.setCookie(data);
     $(this.node).trigger('login.user_status', data);
   };

   proto.setUsername = function(name) {
     $(this.usernameNode).html(name);
   };

   proto.setFullName = function(fullName) {
     $(this.fullNameNode).html(fullName);
   };
   
   proto.updateLogin = function(data) {
     this.setUsername(data.username);
     this.setFullName(data.fullName);     
   };

   proto.logout = function() {
     this.val = this.getCookie();
     $(document.body).toggleClass('logged-in', false);
     var data = {};
     this.updateLogin(data);
     this.setCookie(data);
     $(this.node).trigger('logout.user_status', data);
   }

   proto.getCookie = function() {
     return Cookies.get(COOKIE_NAME);
   };

   proto.setCookie = function(value) {
     return Cookies.set(COOKIE_NAME, value);
   };

   proto.isLogged = function() {
     return !(typeof this.getCookie()==='undefined')
   };
   
   proto.attachHandlers = function() {
     $(document).on('login.user_status', $.proxy(function(e, data) {
                                                   this.updateLogin(data);
                                                 }, this));
     $(document).on('logout.user_status', $.proxy(function() {
       this.updateLogin({});
     }, this));
   };

   $(document).trigger('registerComponent.builder', {'UserStatus': UserStatus});
 }(jQuery));
