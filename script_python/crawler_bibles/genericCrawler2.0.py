__author__ = 'alexandre s. cavalcante'

import requests, time, random, codecs
from lxml import html

class MyBibleCrawler:

    def __init__(self):
        self.url_treated = []
        self.control_url = open('control_url.txt', "r+")

        for item in self.control_url:
            self.url_treated.append(item.strip())

    def getBible(self, url):

        self.url = url

        # variable to keep the structure of the website crawled
        self.page = None

        self.urlBible = "https://www.wordproject.org/bibles/" + self.url

        self.page = self.getPage(self.urlBible)

        # get the html structure
        self.tree = html.fromstring(self.page.text)

        # parser the page of books index
        books_index = self.tree.xpath("//ul[@id='maintab']/li/a/@href")

        self.new_url = self.urlBible.split("index.htm")

        if len(books_index) > 0:

            for item in books_index:

                self.getChapter( self.new_url[0] + item)
        else:
            #verify book_number_temp is empty print error
            print("####Fail to write the url : " + self.urlChapter + '\n')
            print("problem : test line 30  - no value for books_index")
            print(time.strftime('%X %x %Z')+'\n')


    def getChapter(self, urlChapter):

        # set the value passed has argument to be used by the function
        self.urlChapter = urlChapter

        #todo criar estrutura para prosseguir o crawler dos capitulos precedentes, ao inves de passar para o proximo livro

        # get the bible structure to crawl next chapter of the same book without exceeding its limite
        self.bibleStru = self.createBibleStruct()

        #get the chapter no of chapters
        self.total_chatpers = self.bibleStru[urlChapter.split('/')[5]]

        # get the chapter we are treating
        self.count_chapter = int(urlChapter.split('/')[5])

        # try all the url the chapter, before passing to next book
        while(self.total_chatpers + 1 > self.count_chapter):

            if not (self.urlChapter in self.url_treated):


                print("treating url : " + self.urlChapter)
                print(time.strftime('%X %x %Z')+'\n')

               # url not has been treated yet. proceeding treatment
                self.url_treated.append(self.urlChapter)
                self.control_url.write(self.urlChapter+'\n')

                # variable to keep the structure of the website crawled
                self.pageChapter = None

                # get the page
                self.pageChapter = self.getPage(self.urlChapter)

                # get the html structure
                self.treeChapter = html.fromstring(self.pageChapter.text)
                self.crawl = True
                break

            else:
                print('url '+ self.urlChapter + 'has been treated already. Pass to next chapter ')
                # increment chapter
                self.count_chapter +=1

                #build new url
                self.urltemp = urlChapter.split('/')
                self.urlChapter = "https://" + "/".join(self.urltemp[2:6]) + '/' + str(self.count_chapter) + '.htm'

                self.crawl = False


        self.book_number_temp = self.urlChapter.split('/')

        # variable to hold the number of book that we are reading
        self.book_number = ""

        #verify if the book_number_temp is not empty
        if len(self.book_number_temp) > 0:
            # get the book number which is the 5 position of the array
            self.book_number = self.book_number_temp[5]
        else:
            #verify book_number_temp is empty print error
            print("####Fail to write the url : " + self.urlChapter + '\n')
            print("problem : test line 77  - no value for book_number_temp")
            print(time.strftime('%X %x %Z')+'\n')
            return None


        if self.crawl:
            self.file_name_temp = self.urlChapter.split('/')

            # get the language initial from url to build the file name
            self.file_name = ""

            #verify if the file_name_temp is not empty
            if len(self.file_name_temp) > 0:

                # get the file_name_temp which is the 4 position of the array
                self.file_name = self.file_name_temp[4]
            else:
                #verify file_name_temp is empty print error
                print("####Fail to write the url : " + self.urlChapter + '\n')
                print("problem : test line 93  - no value for file_name_temp")
                print(time.strftime('%X %x %Z')+'\n')
                return None

            # create the file to write the extracted information
            self.bible = codecs.open("./bibles/" + self.file_name + self.book_number + ".txt", "a", encoding="utf-8")

            # parser the page of books index
            self.chapter = self.treeChapter.xpath("//div[@id='textBody']/p/text()")

            # parser the page of books index
            self.title = self.treeChapter.xpath("//div[@class='textBody']/h3/text()")

            # verify if the self.title is not empty
            if len(self.title) > 0:
                self.bible.write(str(self.title[0] + '\n'))
            else:
                print("# ERROR Non Fatal to write the url : " + self.urlChapter + '\n')
                print("problem : test line 114  - no value for titre")
                print(time.strftime('%X %x %Z')+'\n')

            # verify if the self.title is not empty
            if len(self.chapter) > 0:
                # write the chapter
                for item in self.chapter:
                    self.bible.write(str(item.rstrip()+'\n'))
            else:
                print("# ERROR Non Fatal to write the url : " + self.urlChapter + '\n')
                print("problem : test line 122  - no value for chapter")
                print(time.strftime('%X %x %Z')+'\n')

            # close buffer
            self.bible.close()

            # get the number of chapters
            self.nb_of_chapter = int(self.treeChapter.xpath('count(//p[@class="ym-noprint"]/a)') + 1)

            # get the actual chapters
            self.actual_chapter = int(self.urlChapter.split('/')[6].split('.htm')[0])

            print("Treating done for : " + self.urlChapter)
            print(time.strftime('%X %x %Z')+'\n')

            if not ( self.actual_chapter == self.nb_of_chapter):

                # get the next chapter index
                self.next_chapter = self.treeChapter.xpath("//span[@class='c1']/following-sibling::*[1]/text()")

                if (len(self.next_chapter) > 0):

                    # replace the number of the chapter in the url
                    self.new_url2 = "https://" + "/".join(self.urlChapter.split("/")[2:6]) + "/" + self.next_chapter[0].lstrip(" ") + ".htm"

                    # call the function recursively
                    self.getChapter(self.new_url2)
                else:
                    print("# Possible Error : no chapter continuation found for " + self.urlChapter)
            else:
                print("Book done  " + self.urlChapter)
                print("Going to next book")


    def getPage(self, url):

        # set the value passed has argument to be used by the function
        self.url = url

        # variable to keep the structure of the website crawled
        self.page = None

        self.tentative_nb = 0

        # try to connect
        while(self.tentative_nb < 10):

            # try catch connection erros
            try:
                self.page = requests.get(self.url)

                if not ("NoneType" ==type(self.page)):


                    if(self.page.status_code == 200):
                        # sleep com random para dormir com intervalos diferentes
                        tempo = random.random() * 17

                        print('url sucefully crawled- ' + self.url)
                        print('going to sleep... ' + str(tempo))
                        time.sleep(tempo)


                    break

            except requests.exceptions.RequestException as err:

                print(str(err))
                self.tentative_nb += 1

                # sleep before try connect again. the sleep time increases with the number of tentatives
                wait_time = 60 * self.tentative_nb

                print("Trying in ...", wait_time)

                # go to sleep
                time.sleep(wait_time)
                pass

        self.page.encoding = 'utf-8'

        # return the page
        return self.page

    def check_status(self):

        # array to stock the bible not complete
        self.list_of_not_completes = []

        # dict to stock the number of url for each bible
        self.prefixe_count = {}

        #read the control file of url done
        self.control_file = open('control_url.txt', 'r')

        # read lines of file control file
        for item in self.control_file:

            # extract language prefixe of url
            self.lang_prefixe = item.split('/')[4]

            # verify if the language prefix is already in the dict
            if not self.lang_prefixe in self.prefixe_count:
                # if not, create the language prefix
                self.prefixe_count[self.lang_prefixe] = 1
            else:
                # prefix is already present, increment variable
                self.prefixe_count[self.lang_prefixe] +=1

        for item in self.prefixe_count.keys():

            self.total = self.prefixe_count[item]

            # verify if the prefix is not complete
            if self.total < 1189:
                self.list_of_not_completes.append(item)

        return self.list_of_not_completes


    def createBibleStruct(self):

        self.bibleStru = open('model_bible.txt', 'r')

        self.chapter = {}

        for item in self.bibleStru:

            if item.split('/')[5] in self.chapter:
                self.chapter[item.split('/')[5]] +=1
            else:
                self.chapter[item.split('/')[5]] = 1

        return  self.chapter


# url start
url = "https://www.wordproject.org/bibles/index.htm"

# variable to keep the structure of the website crawled
page = None

tentative_nb = 0
while(tentative_nb < 10):

    # try catch connection erros
    try:
        page = requests.get(url)

        if not ("NoneType" ==type(page)):
            break

    except requests.exceptions.RequestException as err:
        tentative_nb += 1

        # sleep before try connect again. the sleep time increases with the number of tentatives
        time.sleep(60 * tentative_nb)
        pass
        print("erro no request")


# get the html structure
tree = html.fromstring(page.text)

# obtain the bible index
bible_index = tree.xpath("//ul[@id='maintab']/li/a/@href")

crawler = MyBibleCrawler()
not_completes = crawler.check_status()
crawler.createBibleStruct()


# iterate over bible_index to crawl all the bibles
for item in bible_index:

        if item.split('/')[0] in not_completes:

            print("treating Bible - " + item)
            crawler.getBible(str(item))

            # sleep com random para dormir com intervalos diferentes
            tempo = random.random() * 17

            print('\n Dormindo ' + str(tempo))
            time.sleep(tempo)
