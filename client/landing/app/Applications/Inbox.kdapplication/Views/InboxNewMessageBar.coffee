class InboxNewMessageBar extends KDView
  viewAppended:->
    inboxMessageView = @
    
    @addSubView newMessageButton = new KDButtonView
      title     : "New Message"
      style     : "clean-gray new-message-button"
      callback  : => @createNewMessageModal()

    @addSubView markAsReadBtn = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "mark-unread"
      tooltip     : 
        title     : "Mark as Unread"
        placement : "left"
      callback    : =>
        @propagateEvent KDEventType: 'MessageShouldBeMarkedAsUnread'
    
    
    
    @addSubView deleteMessageButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "delete"
      tooltip     : 
        title     : "Delete message"
        placement : "left"
      callback    : =>
        @propagateEvent KDEventType: 'MessageShouldBeDisowned'

  createNewMessageModal:->
    modal = new KDModalViewWithForms
      title                   : "Compose a message"
      content                 : ""
      cssClass                : "compose-message-modal"
      height                  : "auto"
      width                   : 500
      overlay                 : yes
      tabs                    :
        navigable             : yes
        callback              : (formOutput)=>
          callback = modal.destroy.bind modal
          @propagateEvent KDEventType : "MessageShouldBeSent", {formOutput,callback}
        forms                 :
          sendForm            :
            fields            :
              to              :
                label         : "Send To:"
                type          : "hidden"
                name          : "dummy"
              subject         :          
                label         : "Subject:"
                placeholder   : 'Enter a subject'
                name          : "subject"
              Message         :          
                label         : "Message:"
                type          : "textarea"
                name          : "body"
                placeholder   : 'Enter your message'
            buttons           :
              Send            :
                title         : "Send"
                style         : "modal-clean-gray"
                type          : "submit"
              Cancel          :
                title         : "cancel"
                style         : "modal-cancel"
                callback      : -> modal.destroy()
    
    toField = modal.modalTabs.forms.sendForm.fields.to
    
    recipientsWrapper = new KDView
      cssClass      : "completed-items"
    
    recipient = new KDAutoCompleteController
      name                : "recipient"
      itemClass           : MemberAutoCompleteItemView
      selectedItemClass   : MemberAutoCompletedItemView
      outputWrapper       : recipientsWrapper
      form                : modal.modalTabs.forms.sendForm
      # itemDataPath        : "profile.nickname"
      listWrapperCssClass : "users"
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in recipient.getSelectedItemData())
        # callback []
        @propagateEvent KDEventType : "AutoCompleteNeedsMemberData", {inputValue,blacklist,callback}

    toField.addSubView recipient.getView()
    toField.addSubView recipientsWrapper


    @propagateEvent KDEventType: "NewMessageModalShouldOpen"

    