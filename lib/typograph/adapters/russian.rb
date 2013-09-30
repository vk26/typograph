# encoding: utf-8

module Typograph
  module Adapters
    class Russian < Adapter

      OPTIONS = {
        :ndash => '–',
        :mdash => '—',
        :minus => '-',
        :orphan => false
      }

      def initialize(options={})
        @options = OPTIONS.dup.merge(options)

        ndash = @options[:ndash]
        mdash = @options[:mdash]
        minus = @options[:minus]

        abbr = 'ООО|ОАО|ЗАО|ЧП|ИП|НПФ|НИИ|ООО\p{Zs}ТПК'
        prepos = 'а|в|во|вне|и|к|о|с|у|со|об|обо|от|ото|то|на|не|ни|но|из|изо|за|уж|на|по|подо|пред|предо|про|над|надо|как|без|безо|да|до|там|ещё|их|ко|меж|между|перед|передо|около|через|сквозь|при|я'
        # что|для|или|под
        metrics = 'мм|см|м|км|г|кг|б|кб|мб|гб|dpi|px'
        shortages = 'г|гр|тов|пос|c|ул|д|пер|м|зам|им|бул'
        money = 'руб\.|долл\.|евро|у\.е\.'
        countables = 'млн|тыс'

        @rules_strict = {
          # Много пробелов или табуляций -> один пробел
          /( |\t)+/ => ' ',
          # Запятые после «а» и «но». Если уже есть — не ставим.
          /([а-яA-я0-9])\s(а|но)\s/ => '\1, \2 ',
        }

        @rules_symbols = {
          # Лишние знаки.
          # TODO: сделать красиво
          /([^!])!!([^!])/ => '\1!\2',
          /([^?])\?\?([^?])/ => '\1?\2',
          /(\p{L})\s*\.\.(\p{Zs})/ => '\1.\2', # new
          /(\p{L});[;\s]*(;)/ => '\1;', # new
          /(\p{L}),[,\s]*(,)/ => '\1,', # new
          /(\p{L}):[:\s]*(:)/ => '\1:', # new

          /([!\?])\s*(!\s*)[!\s]*(!)/     => '\1!!', # new
          /(\?\s*)(\?\s*)[\?\s]*(\?)/ => '???', # new
          /(\.\s*)(\.\s*)[\.\s]*(\.)/ => '...', # new
          /(,\s*)[,\s]*(,)/ => ',', # new
          /;{2,}/ => ';', # new
          /,{2,}/ => ',', # new
          /:{2,}/ => ':', # new

          # /([;,:])(\S)/ => '\1 \2', # new

          # Занятная комбинация
          /!\?/ => '?!',

          # Знаки (c), (r), (tm)
          /\((c|с)\)/i => '©',
          /\(r\)/i     => '<sup><small>®</small></sup>',
          /\(tm\)/i    => '™',

          # От 2 до 5 знака точки подряд - на знак многоточия (больше - мб авторской задумкой).
          /\s*\.{2,5}/ => '…',

          # Дроби
          # TODO: найти замену \b
          /\b1\/2\b/ => '½',
          /\b1\/3\b/ => '⅓',
          /\b2\/3\b/ => '⅔',
          /\b1\/4\b/ => '¼',
          /\b3\/4\b/ => '¾',
          /\b1\/5\b/ => '⅕',
          /\b2\/5\b/ => '⅖',
          /\b3\/5\b/ => '⅗',
          /\b4\/5\b/ => '⅘',
          /\b1\/6\b/ => '⅙',
          /\b5\/6\b/ => '⅚',
          /\b1\/8\b/ => '⅛',
          /\b3\/8\b/ => '⅜',
          /\b5\/8\b/ => '⅝',
          /\b7\/8\b/ => '⅞',

          # LО'Лайт, O'Reilly
          /([A-Z])''?([а-яА-Яa-zA-Z])/i => '\1’\2',

          /'/ => '&#39;',

          # Размеры 10x10, правильный знак + убираем лишние пробелы
          /(\p{Nd}+)\p{Zs}{0,}?[x|X|х|Х|*]\p{Zs}{0,}(\p{Nd}+)/ => '\1×\2',

          # +-
          /([^\+]|^)\+\/?-/ => '\1±',

          # Стрелки
          /([^-]|^)->/ => '\1→',
          /<-([^-]|$)/ => '←\1'
        }

        @rules_quotes = {
          # Разносим неправильные кавычки
          /([^"]\p{L}+)"(\p{L}+)"/ => '\1 "\2"',
          /"(\p{L}+)"(\p{L}+)/ => '"\1" \2',

          # Превращаем кавычки в ёлочки.
          /(\p{^L})?"([^"]*)"(\p{^L})?/ => '\1«\2»\3'
        }

        @rules_braces = {
          # Оторвать скобку от слова
          /(\p{L})\(/ => '\1 (',
          # Слепляем скобки со словами
          /\( /m => '(',
          / \)/m => ')'
        }

        @rules_main = {
          # Конфликт с «газо- и электросварка»
          # Оторвать тире от слова
          # /(\p{L})- / => '\1 - ',

          # P.S., P.P.S - конфликтует с правилом инициалов.
          'P.P.S.' => '<nobr>P. P. S.</nobr>',
          /([^.]|^)P\.S\./ => '\1<nobr>P. S.</nobr>',
          # /и(&nbsp;|\s)?т(&nbsp;|\s)?\.?д(&nbsp;|\s)?\.{0,2}/ => "<nobr>и т. д.</nobr>",
          # /и(&nbsp;|\s)?т(&nbsp;|\s)?\.?п(&nbsp;|\s)?\.{0,2}/ => "<nobr>и т. п.</nobr>",
          # /в(&nbsp;|\s)?т(&nbsp;|\s)?\.?ч(&nbsp;|\s)?\.{0,2}/ => "<nobr>в т. ч.</nobr>",

          # Знаки с предшествующим пробелом… нехорошо!
          # /(\p{L}|>|\p{Nd}) +([?!:,;…])/ => '\1\2',
          # /([?!:,;])(\p{L}|<)/ => '\1 \2',
          # Для точки отдельно
          /(\p{L})\p{Zs}(?:\.)(\p{Zs}|$)/ => '\1.\2',
          # Но перед кавычками пробелов не ставим
          /([?!:,;\.])\p{Zs}(»)/ => '\1\2',

          # Неразрывные названия организаций и абревиатуры форм собственности
          # ~ почему не один &nbsp;?
          # ! названия организаций тоже могут содержать пробел !
          /(#{abbr})\p{Zs}+(«[^»]*»)/ => '<nobr>\1 \2</nobr>',

          # Нельзя отрывать сокращение от относящегося к нему слова.
          # Например: тов. Сталин, г. Воронеж
          # Ставит пробел, если его нет.
          /(^|[^a-zA-Zа-яА-Я])(#{shortages})\.\s?([А-Я0-9]+)/m => '\1\2.&nbsp;\3',
          /(^|[^a-zA-Zа-яА-Я])(см)\.\s?([А-Яа-я]+)/m => '\1\2.&nbsp;\3',

          # Не отделять стр., с. и т.д. от номера.
          /(стр|с|табл|рис|илл|гл)\.\p{Zs}*(\p{Nd}+)/mi => '\1.&nbsp;\2',

          # Не разделять 2007 г., ставить пробел, если его нет. Ставит точку, если её нет.
          /(\p{Nd}+)\p{Zs}*([гГ])\.\s/m => '\1&nbsp;\2. ',
          /(\p{Nd}+)\p{Zs}*-\p{Zs}*(\p{Nd}+)г\.?г\./ => "<nobr>\\1—\\2 гг.</nobr>",
          /(\d\d\.\d\d\.\d\d\d?\d?)(\s|&nbsp;)*г\.?(\s|&nbsp;)/ => "<nobr>\\1 г.</nobr> ",

          # Неразрывный пробел между цифрой и единицей измерения
          /(\p{Nd}+)\s*(#{metrics})/m => '\1&nbsp;\2',

          # Сантиметр и другие ед. измерения в квадрате, кубе и т.д.
          /(\p{Zs}#{metrics})2/ => '\1&sup2;',
          /(\p{Zs}#{metrics})3/ => '\1&sup3;',
          /(\p{Zs}#{metrics})(\p{Nd}+)/ => '\1<sup>\2</sup>',

          # Знак дефиса или два знака дефиса подряд — на знак длинного тире.
          # + Нельзя разрывать строку перед тире, например: Знание&nbsp;— сила, Курить&nbsp;— здоровью вредить.
          /\p{Zs}+(?:--?|—)(?=\p{Zs})/ => "&nbsp;#{mdash}",
          /^(?:--?|—)(?=\p{Zs})/ => mdash,

          # Прямая речь
          /(?:^|\s+)(?:--?|—)(?=\p{Zs})/ => '\0',

          # Знак дефиса, ограниченный с обоих сторон цифрами — на знак короткого тире.
          /(?<=\p{Nd})-(?=\p{Nd})/ => minus,

          # Знак дефиса, ограниченный с обоих сторон пробелами — на знак длинного тире.
          /(\s)(&ndash;|–)(\s)/ => "&nbsp;#{mdash} ",

          # Знак дефиса, идущий после тэга и справа пробел — на знак длинного тире.
          /(?<=>)(&ndash;|–|-)(\s)/ => "#{mdash} ",

          # Расстановка дефиса перед -ка, -де, -кась
          # /\b(\S+)[\s-](ка|де|кась)\b/ => "<nobr>\\1#{ndash}\\2</nobr>",

          # Расстановка дефиса после кое-, кой-
          /\b(кое|кой)[\s-](как|кого|какой)\b/i => "<nobr>\\1#{ndash}\\2</nobr>",

          # Расстановка дефиса перед -то, -либо, -нибудь
### to od          /(кто|что|где|когда|почему|зачем|кем|чем|как|чего)(\s|-|–|—|&nbsp;)+(либо|нибудь|то)([^:]|$)/i => "<nobr>\\1#{ndash}\\3</nobr>\\4",

          # Расстановка дефиса перед -таки
          /(все)(\s|-|–|—|&nbsp;)+(таки)/i => "<nobr>\\1#{ndash}\\3</nobr>",

          # Расстановка дефисов в предлогах «из-за», «из-под», «по-над», «по-под».
          /\b(из)[\s-]?(за|под)\b/i => "<nobr>\\1#{ndash}\\2</nobr>",
          /\b(по)[\s-]?(над|под)\b/i => "<nobr>\\1#{ndash}\\2</nobr>",

          # Нельзя оставлять в конце строки предлоги и союзы
          /(?<=\p{Zs}|^|\p{^L})(#{prepos})(\s+)/i => '\1&nbsp;',

          # Нельзя отрывать частицы бы, ли, же от предшествующего слова, например: как бы, вряд ли, так же.
          /(?<=\p{^Zs})(\p{Zs}+)(ж|бы|б|же|ли|ль|либо)(?=(<.*?>)*[\p{Zs})!?.…])/i => '&nbsp;\2',
          # |или

          # Неразрывный пробел после инициалов.
          /([А-ЯA-Z]\.)\s?([А-ЯA-Z]\.)\p{Zs}?([А-ЯA-Z][а-яa-z]+)/m => '\1\2&nbsp;\3',

          # Сокращения сумм не отделяются от чисел.
          /(\p{Nd}+)\p{Zs}?(#{countables})/m   =>  '\1&nbsp;\2',

          # «уе» в денежных суммах
          /(\p{Nd}+|#{countables})\p{Zs}?уе/m  =>  '\1&nbsp;у.е.',

          # Денежные суммы, расставляя пробелы в нужных местах.
          /(\p{Nd}+|#{countables})\p{Zs}?(#{money})/m  =>  '\1&nbsp;\2',

          # Неразрывные пробелы в кавычках
          # "/($sym[lquote]\S*)(\s+)(\S*$sym[rquote])/U" => '\1'.\sym["nbsp"].'\3',

          # Телефоны
          /(?:тел\.?\/?факс:?\s?\((\d+)\))/i => 'тел./факс:&nbsp(\1)',

          /тел[:\.] ?(\p{Nd}+)/m => '<nobr>тел: \1</nobr>',

          # Номер версии программы пишем неразрывно с буковкой v.
          /([vв]\.) ?(\p{Nd})/i => '\1&nbsp;\2',
          /(\p{L}) ([vв]\.)/i => '\1&nbsp;\2',

          # % не отделяется от числа
          /(\p{Nd}+)\p{Zs}+%/ => '\1%',

          # IP-адреса рвать нехорошо
          /(1\p{Nd}{0,2}|2(\p{Nd}|[0-5]\p{Nd}+)?)\.(0|1\p{Nd}{0,2}|2(\p{Nd}|[0-5]\p{Nd})?)\.(0|1\p{Nd}{0,2}|2(\p{Nd}|[0-5]\p{Nd})?)\.(0|1\p{Nd}{0,2}|2(\p{Nd}|[0-5]\p{Nd})?)/ =>
          '<nobr>\0</nobr>',

          # Делаем неразрывными слова с дефисом. 
          # Пример: "слово-слово", "слово-слово-слово".
          /(\^|;)((\p{L}+((&ndash;|–|-)\p{L}+){1,2}))/ => '\1<nobr>\2</nobr>',

          # Меняем ё на е и Ё на Е
          /ё/ => 'е',
          /Ё/ => 'Е',

        }

        # Неразрывный пробел перед последним словом в тексте
        @rules_main[/(\s)(\S+)\Z/] = '&nbsp;\2' if options[:orphan]

      end

      def apply_rules(rules, str)
        res = str.dup
        rules.each do |rul, rep|
          str.gsub!(rul, rep)
        end
        str
      end

      def process(str)
        # str = apply_rules(rules_quotes, str) <------- DON'T WORK PROP!!!
        str = apply_rules(@rules_strict, str) #  Сначала применим строгие правила: пробелы, запятые
        str = quotes(str) #  правильно расставим кавычки
        str = apply_rules(@rules_main, str)
        str = apply_rules(@rules_symbols, str)
        str = apply_rules(@rules_braces, str)
      end

      def quotes(text)
        quot11='«'
        quot12='»'
        quot21='«'
        quot22='»'
        # quot21='„'
        # quot22='“'

        quotes = ['&quot;','&laquo;','&raquo;','«','»','&#171;','&#187;','&#147;','&#132;','&#8222;','&#8220;','„','“','”','‘','’']
        quotes = Regexp.new quotes.join('|')
        text.gsub!(quotes, '"') #  Единый тип кавычек
        text.gsub!('""', '"')

        text.gsub!(/"(\p{^L})/, '»\1') #  Взято из старой реализации
        text.gsub!(/(\p{^L})"/, '\1«') #  Взято из старой реализации

#       text.gsub!(/([^=]|\A)""(\.{2,4}[а-яА-Я\w\-]+|[а-яА-Я\w\-]+)/, '\1<typo:quot1>"\2') #  Двойных кавычек уже нет
        text.gsub!(/([^=]|\A)"(\.{2,4}[\p{L}\p{M}]+|[\p{L}\p{M}\-]+)/, '\1<typo:quot1>\2')
#       text.gsub!(/([а-яА-Я\w\.\-]+)""([\n\.\?\!, \)][^>]{0,1})/, '\1"</typo:quot1>\2') #  Двойных кавычек уже нет
        text.gsub!(/([\p{L}\p{M}\.\-]+)"([\n\.\?\!, \)][^>]{0,1})/, '\1</typo:quot1>\2')
        text.gsub!(/(<\/typo:quot1>[\.\?\!]{1,3})"([\n\.\?\!, \)][^>]{0,1})/, '\1</typo:quot1>\2')
        text.gsub!(/(<typo:quot1>[\p{L}\p{M}\.\- \n]*?)<typo:quot1>(.+?)<\/typo:quot1>/, '\1<typo:quot2>\2</typo:quot2>')
        text.gsub!(/(<\/typo:quot2>.+?)<typo:quot1>(.+?)<\/typo:quot1>/, '\1<typo:quot2>\2</typo:quot2>')
        text.gsub!(/(<typo:quot2>.+?<\/typo:quot2>)\.(.+?<typo:quot1>)/, '\1</typo:quot1>.\2')
        text.gsub!(/(<typo:quot2>.+?<\/typo:quot2>)\.(?!<\/typo:quot1>)/, '\1</typo:quot1>.\2\3\4')
#       text.gsub!(/""/, '</typo:quot2></typo:quot1>') #  Двойных кавычек уже нет
        text.gsub!(/(?<=<typo:quot1>)(.+?)<typo:quot2>(.+?)(?!<\/typo:quot2>)/, '\1<typo:quot2>\2')
#       text.gsub!(/"/, '<typo:quot1>') #  Непонятный хак
#       text.gsub!(/(<[^>]+)<\/typo:quot\d>/, '\1"') #  Еще более непонятный хак

        text.gsub!(/"$/, '</typo:quot2>') # new

        text.gsub!('<typo:quot1>', quot11)
        text.gsub!('</typo:quot1>', quot12)
        text.gsub!('<typo:quot2>', quot21)
        text.gsub!('</typo:quot2>', quot22)

        text.gsub!(/(^|\s)»(<)/, '\1«\2') # new
        text.gsub!(/([а-я\w\d,])«(.)/i, '\1 «\2') # new
        text.gsub!(/» ([:,])/i, '»\1') # new
        text.gsub!(/«$/, '»') # new
        text.gsub!(/^»/, '«') # new
        text.gsub!('.».', '».') # new
        text.gsub!(/ »(.)/, ' «\1') # new
        text.gsub!(/^«\s+/, '«') # new
        text.gsub!(/\s+»$/, '»') # new

        text
      end
    end
  end
end
     
