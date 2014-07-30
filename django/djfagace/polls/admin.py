from django.contrib import admin
# Register your models here.
from polls.models import Question, Choice
#admin.site.register(Question)
#admin.site.register(Choice)
#class ChoiceInline(admin.StackedInline):
class ChoiceInline(admin.TabularInline):
    model = Choice
    extra = 3

'''class QuestionAdmin(admin.ModelAdmin):
	fields=['pub_date','question_text']'''
class QuestionAdmin(admin.ModelAdmin):
    fieldsets = [
        (None,               {'fields': ['question_text']}),
        ('Date information', {'fields': ['pub_date'], 'classes': ['collapse']}),
    ]
    inlines = [ChoiceInline]
    list_display = ('question_text', 'pub_date', 'was_published_recently')
    #list_filter = ['pub_date']

    #def was_published_recently(self):
        #return self.pub_date >= timezone.now() - datetime.timedelta(days=1)

    #was_published_recently.admin_order_field = 'pub_date'
    #was_published_recently.boolean = True
    #was_published_recently.short_description = 'Published recently?'
# Register classes from admin view 
admin.site.register(Question,QuestionAdmin)