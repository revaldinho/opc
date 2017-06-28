

## Different spigot, use base 100 to compute triplets
##
## python3  pi.py digits  base

import math,sys

def check_pi(pistr):

    pi_ref="31415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632788659361533818279682303019520353018529689957736225994138912497217752834791315155748572424541506959508295331168617278558890750983817546374649393192550604009277016711390098488240128583616035637076601047101819429555961989467678374494482553797747268471040475346462080466842590694912933136770289891521047521620569660240580381501935112533824300355876402474964732639141992726042699227967823547816360093417216412199245863150302861829745557067498385054945885869269956909272107975093029553211653449872027559602364806654991198818347977535663698074265425278625518184175746728909777727938000816470600161452491921732172147723501414419735685481613611573525521334757418494684385233239073941433345477624168625189835694855620992192221842725502542568876717904946016534668049886272327917860857843838279679766814541009538837863609506800642251252051173929848960841284886269456042419652850222106611863067442786220391949450471237137869609563643719172874677646575739624138908658326459958133904780275900994657640789512694683983525957098258226205224894077267194782684826014769909026401363944374553050682034962524517493996514314298091906592509372216964615157098583874105978859597729754989301617539284681382686838689427741559918559252459539594310499725246808459872736446958486538367362226260991246080512438843904512441365497627807977156914359977001296160894416948685558484063534220722258284886481584560285060168427394522674676788952521385225499546667278239864565961163548862305774564980355936345681743241125150760694794510965960940252288797108931456691368672287489405601015033086179286809208747609178249385890097149096759852613655497818931297848216829989487226588048575640142704775551323796414515237462343645428584447952658678210511413547357395231134271661021359695362314429524849371871101457654035902799344037420073105785390621983874478084784896833214457138687519435064302184531910484810053706146806749192781911979399520614196634287544406437451237181921799983910159195618146751426912397489409071864942319615679452080951465502252316038819301420937621378559566389377870830390697920773467221825625996615014215030680384477345492026054146659252014974428507325186660021324340881907104863317346496514539057962685610055081066587969981635747363840525714591028970641401109712062804390397595156771577004203378699360072305587631763594218731251471205329281918261861258673215791984148488291644706095752706957220917567116722910981690915280173506712748583222871835209353965725121083579151369882091444210067510334671103141267111369908658516398315019701651511685171437657618351556508849099898599823873455283316355076479185358932261854896321329330898570642046752590709154814165498594616371802709819943099244889575712828905923233260972997120844335732654893823911932597463667305836041428138830320382490375898524374417029132765618093773444030707469211201913020330380197621101100449293215160842444859637669838952286847831235526582131449576857262433441893039686426243410773226978028073189154411010446823252716201052652272111660396665573092547110557853763466820653109896526918620564769312570586356620185581007293606598764861179104533488503461136576867532494416680396265797877185560845529654126654085306143444318586769751456614068007002378776591344017127494704205622305389945613140711270004078547332699390814546646458807972708266830634328587856983052358089330657574067954571637752542021149557615814002501262285941302164715509792592309907965473761255176567513575178296664547791745011299614890304639947132962107340437518957359614589019389713111790429782856475032031986915140287080859904801094121472213179476477726224142548545403321571853061422881375850430633217518297986622371721591607716692547487389866549494501146540628433663937900397692656721463853067360965712091807638327166416274888800786925602902284721040317211860820419000422966171196377921337575114959501566049631862947265473642523081770367515906735023507283540567040386743513622224771589150495309844489333096340878076932599397805419341447377441842631298608099888687413260472156951623965864573021631598193195167353812974167729478672422924654366800980676928238280689964004824354037014163149658979409243237896907069779422362508221688957383798623001593776471651228935786015881617557829735233446042815126272037343146531977774160319906655418763979293344195215413418994854447345673831624993419131814809277771038638773431772075456545322077709212019051660962804909263601975988281613323166636528619326686336062735676303544776280350450777235547105859548702790814356240145171806246436267945612753181340783303362542327839449753824372058353114771199260638133467768796959703098339130771098704085913374641442822772634659470474587847787201927715280731767907707157213444730605700733492436931138350493163128404251219256517980694113528013147013047816437885185290928545201165839341965621349143415956258658655705526904965209858033850722426482939728584783163057777560688876446248246857926039535277348030480290058760758251047470916439613626760449256274204208320856611906254543372131535958450687724602901618766795240616342522577195429162991930645537799140373404328752628889639958794757291746426357455254079091451357111369410911939325191076020825202618798531887705842972591677813149699009019211697173727847684726860849003377024242916513005005168323364350389517029893922334517220138128069650117844087451960121228599371623130171144484640903890644954440061986907548516026327505298349187407866808818338510228334508504860825039302133219715518430635455007668282949304137765527939751754613953984683393638304746119966538581538420568533862186725233402830871123282789212507712629463229563989898935821167456270102183564622013496715188190973038119800497340723961036854066431939509790190699639552453005450580685501956730229219139339185680344903982059551002263535361920419947455385938102343955449597783779023742161727111723643435439478221818528624085140066604433258885698670543154706965747458550332323342107301545940516553790686627333799585115625784322988273723198987571415957811196358330059408730681216028764962867446047746491599505497374256269010490377819868359381465741268049256487985561453723478673303904688383436346553794986419270563872931748723320837601123029911367938627089438799362016295154133714248928307220126901475466847653576164773794675200490757155527819653621323926406160136358155907422020203187277605277219005561484255518792530343513984425322341576233610642506390497500865627109535919465897514131034822769306247435363256916078154781811528436679570611086153315044521274739245449454236828860613408414863776700961207151249140430272538607648236341433462351897576645216413767969031495019108575984423919862916421939949072362346468441173940326591840443780513338945257423995082965912285085558215725031071257012668302402929525220118726767562204154205161841634847565169998116141010029960783869092916030288400269104140792886215078424516709087000699282120660418371806535567252532567532861291042487761825829765157959847035622262934860034158722980534989650226291748788202734209222245339856264766914905562842503912757710284027998066365825488926488025456610172967026640765590429099456815065265305371829412703369313785178609040708667114965583434347693385781711386455873678123014587687126603489139095620099393610310291616152881384379099042317473363948045759314931405297634757481193567091101377517210080315590248530906692037671922033229094334676851422144773793937517034436619910403375111735471918550464490263655128162288244625759163330391072253837421821408835086573917715096828874782656995995744906617583441375223970968340800535598491754173818839994469748676265516582765848358845314277568790029095170283529716344562129640435231176006651012412006597558512761785838292041974844236080071930457618932349229279650198751872127267507981255470958904556357921221033346697499235630254947802490114195212382815309114079073860251522742995818072471625916685451333123948049470791191532673430282441860414263639548000448002670496248201792896476697583183271314251702969234889627668440323260927524960357996469256504936818360900323809293459588970695365349406034021665443755890045632882250545255640564482465151875471196218443965825337543885690941130315095261793780029741207665147939425902989695946995565761218656196733786236256125216320862869222103274889218654364802296780705765615144632046927906821207388377814233562823608963208068222468012248261177185896381409183903673672220888321513755600372798394004152970028783076670944474560134556417254370906979396122571429894671543578468788614445812314593571984922528471605049221242470141214780573455105008019086996033027634787081081754501193071412233908663938339529425786905076431006383519834389341596131854347546495569781038293097164651438407007073604112373599843452251610507027056235266012764848308407611830130527932054274628654036036745328651057065874882256981579367897669742205750596834408697350201410206723585020072452256326513410559240190274216248439140359989535394590944070469120914093870012645600162374288021092764579310657922955249887275846101264836999892256959688159205600101655256375678566722796619885782794848855834397518744545512965634434803966420557982936804352202770984294232533022576341807039476994159791594530069752148293366555661567873640053666564165473217043903521329543529169414599041608753201868379370234888689479151071637852902345292440773659495630510074210871426134974595615138498713757047101787957310422969066670214498637464595280824369445789772330048764765241339075920434019634039114732023380715095222010682563427471646024335440051521266932493419673977041595683753555166730273900749729736354964533288869844061196496162773449518273695588220757355176651589855190986665393549481068873206859907540792342402300925900701731960362254756478940647548346647760411463233905651343306844953979070903023460461470961696886885014083470405460742958699138296682468185710318879065287036650832431974404771855678934823089431068287027228097362480939962706074726455399253994428081137369433887294063079261595995462624629707062594845569034711972996409089418059534393251236235508134949004364278527138315912568989295196427287573946914272534366941532361004537304881985517065941217352462589548730167600298865925786628561249665523533829428785425340483083307016537228563559152534784459818313411290019992059813522051173365856407826484942764411376393866924803118364453698589175442647399882284621844900877769776312795722672655562596282542765318300134070922334365779160128093179401718598599933849235495640057099558561134980252499066984233017350358044081168552653117099570899427328709258487894436460050410892266917835258707859512983441729535195378855345737426085902908176515578039059464087350612322611200937310804854852635722825768203416050484662775045003126200800799804925485346941469775164932709504934639382432227188515974054702148289711177792376122578873477188196825462981268685817050740272550263329044976277894423621674119186269439650671515779586756482399391760426017633870454990176143641204692182370764887834196896861181558158736062938603810171215855272668300823834046564758804051380801633638874216371406435495561868964112282140753302655100424104896783528588290243670904887118190909494533144218287661810310073547705498159680772009474696134360928614849417850171807793068108546900094458995279424398139213505586422196483491512639012803832001097738680662877923971801461343244572640097374257007359210031541508936793008169980536520276007277496745840028362405346037263416554259027601834840306811381855105979705664007509426087885735796037324514146786703688098806097164258497595138069309449401515422221943291302173912538355915031003330325111749156969174502714943315155885403922164097229101129035521815762823283182342548326111912800928252561902052630163911477247331485739107775874425387611746578671169414776421441111263583553871361011023267987756410246824032264834641766369806637857681349204530224081972785647198396308781543221166912246415911776732253264335686146186545222681268872684459684424161078540167681420808850280054143613146230821025941737562389942075713627516745731891894562835257044133543758575342698699472547031656613991999682628247270641336222178923903176085428943733935618891651250424404008952719837873864805847268954624388234375178852014395600571048119498842390606136957342315590796703461491434478863604103182350736502778590897578272731305048893989009923913503373250855982655867089242612429473670193907727130706869170926462548423240748550366080136046689511840093668609546325002145852930950000907151058236267293264537382104938724996699339424685516483261134146110680267446637334375340764294026682973865220935701626384648528514903629320199199688285171839536691345222444708045923966028171565515656661113598231122506289058549145097157553900243931535190902107119457300243880176615035270862602537881797519478061013715004489917210022201335013106016391541589578037117792775225978742891917915522417189585361680594741234193398420218745649256443462392531953135103311476394911995072858430658361935369329699289837914941939406085724863968836903265564364216644257607914710869984315733749648835292769328220762947282381537409961545598798259891093717126218283025848112389011968221429457667580718653806506487026133892822994972574530332838963818439447707794022843598834100358385423897354243956475556840952248445541392394100016207693636846776413017819659379971557468541946334893748439129742391433659360410035234377706588867781139498616478747140793263858738624732889645643598774667638479466504074111825658378878454858148962961273998413442726086061872455452360643153710112746809778704464094758280348769758948328241239292960582948619196670918958089833201210318430340128495116203534280144127617285830243559830032042024512072872535581195840149180969253395075778400067465526031446167050827682772223534191102634163157147406123850425845988419907611287258059113935689601431668283176323567325417073420817332230462987992804908514094790368878687894930546955703072619009502076433493359106024545086453628935456862958531315337183868265617862273637169757741830239860065914816164049449650117321313895747062088474802365371031150898427992754426853277974311395143574172219759799359685252285745263796289612691572357986620573408375766873884266405990993505000813375432454635967504844235284874701443545419576258473564216198134073468541117668831186544893776979566517279662326714810338643913751865946730024434500544995399742372328712494834706044063471606325830649829795510109541836235030309453097335834462839476304775645015008507578949548931393944899216125525597701436858943585877526379625597081677643800125436502371412783467926101995585224717220177723700417808419423948725406801556035998390548985723546745642390585850216719031395262944554391316631345308939062046784387785054239390524731362012947691874975191011472315289326772533918146607300089027768963114810902209724520759167297007850580717186381054967973100167870850694207092232908070383263453452038027860990556900134137182368370991949516489600755049341267876436746384902063964019766685592335654639138363185745698147196210841080961884605456039038455343729141446513474940784884423772175154334260306698831768331001133108690421939031080143784334151370924353013677631084913516156422698475074303297167469640666531527035325467112667522460551199581831963763707617991919203579582007595605302346267757943936307463056901080114942714100939136913810725813781357894005599500183542511841721360557275221035268037357265279224173736057511278872181908449006178013889710770822931002797665935838758909395688148560263224393726562472776037890814458837855019702843779362407825052704875816470324581290878395232453237896029841669225489649715606981192186584926770403956481278102179913217416305810554598801300484562997651121241536374515005635070127815926714241342103301566165356024733807843028655257222753049998837015348793008062601809623815161366903341111386538510919367393835229345888322550887064507539473952043968079067086806445096986548801682874343786126453815834280753061845485903798217994599681154419742536344399602902510015888272164745006820704193761584547123183460072629339550548239557137256840232268213012476794522644820910235647752723082081063518899152692889108455571126603965034397896278250016110153235160519655904211844949907789992007329476905868577878720982901352956613978884860509786085957017731298155314951681467176959760994210036183559138777817698458758104466283998806006162298486169353373865787735983361613384133853684211978938900185295691967804554482858483701170967212535338758621582310133103877668272115726949518179589754693992642197915523385766231676275475703546994148929041301863861194391962838870543677743224276809132365449485366768000001065262485473055861598999140170769838548318875014293890899506854530765116803337322265175662207526951791442252808165171667766727930354851542040238174608923283917032754257508676551178593950027933895920576682789677644531840404185540104351348389531201326378369283580827193783126549617459970567450718332065034556644034490453627560011250184335607361222765949278393706478426456763388188075656121689605041611390390639601620221536849410926053876887148379895599991120991646464411918568277004574243434021672276445589330127781586869525069499364610175685060167145354315814801054588605645501332037586454858403240298717093480910556211671546848477803944756979804263180991756422809873998766973237695737015808068229045992123661689025962730430679316531149401764737693873514093361833216142802149763399189835484875625298752423873077559555955465196394401821840998412489826236737714672260616336432964063357281070788758164043814850188411431885988276944901193212968271588841338694346828590066640806314077757725705630729400492940302420498416565479736705485580445865720227637840466823379852827105784319753541795011347273625774080213476826045022851579795797647467022840999561601569108903845824502679265942055503958792298185264800706837650418365620945554346135134152570065974881916341359556719649654032187271602648593049039787489589066127250794828276938953521753621850796297785146188432719223223810158744450528665238022532843891375273845892384422535472653098171578447834215822327020690287232330053862163479885094695472004795231120150432932266282727632177908840087861480221475376578105819702226309717495072127248479478169572961423658595782090830733233560348465318730293026659645013718375428897557971449924654038681799213893469244741985097334626793321072686870768062639919361965044099542167627840914669856925715074315740793805323925239477557441591845821562518192155233709607483329234921034514626437449805596103307994145347784574699992128599999399612281615219314888769388022281083001986016549416542616968586788372609587745676182507275992950893180521872924610867639958916145855058397274209809097817293239301067663868240401113040247007350857828724627134946368531815469690466968693925472519413992914652423857762550047485295476814795467007050347999588867695016124972282040303995463278830695976249361510102436555352230690612949388599015734661023712235478911292547696176005047974928060721268039226911027772261025441492215765045081206771735712027180242968106203776578837166909109418074487814049075517820385653909910477594141321543284406250301802757169650820964273484146957263978842560084531214065935809041271135920041975985136254796160632288736181367373244506079244117639975974619383584574915988097667447093006546342423460634237474666080431701260052055928493695941434081468529815053947178900451835755154125223590590687264878635752541911288877371766374860276606349603536794702692322971868327717393236192007774522126247518698334951510198642698878471719396649769070825217423365662725928440620430214113719922785269984698847702323823840055655517889087661360130477098438611687052310553149162517283732728676007248172987637569816335415074608838663640693470437206688651275688266149730788657015685016918647488541679154596507234287730699853713904300266530783987763850323818215535597323530686043010675760838908627049841888595138091030423595782495143988590113185835840667472370297149785084145853085781339156270760356390763947311455495832266945702494139831634332378975955680856836297253867913275055542524491943589128405045226953812179131914513500993846311774017971512283785460116035955402864405902496466930707769055481028850208085800878115773817191741776017330738554758006056014337743299012728677253043182519757916792969965041460706645712588834697979642931622965520168797300035646304579308840327480771811555330909887025505207680463034608658165394876951960044084820659673794731680864156456505300498816164905788311543454850526600698230931577765003780704661264706021457505793270962047825615247145918965223608396645624105195510522357239739512881816405978591427914816542632892004281609136937773722299983327082082969955737727375667615527113922588055201898876201141680054687365580633471603734291703907986396522961312801782679717289822936070288069087768660593252746378405397691848082041021944719713869256084162451123980620113184541244782050110798760717155683154078865439041210873032402010685341947230476666721749869868547076781205124736792479193150856444775379853799732234456122785843296846647513336573692387201464723679427870042503255589926884349592876124007558756946413705625140011797133166207153715436006876477318675587148783989081074295309410605969443158477539700943988394914432353668539209946879645066533985738887866147629443414010498889931600512076781035886116602029611936396821349607501116498327856353161451684576956871090029997698412632665023477167286573785790857466460772283415403114415294188047825438761770790430001566986776795760909966936075594965152736349811896413043311662774712338817406037317439705406703109676765748695358789670031925866259410510533584384656023391796749267844763708474978333655579007384191473198862713525954625181604342253729962863267496824058060296421146386436864224724887283434170441573482481833301640566959668866769563491416328426414974533349999480002669987588815935073578151958899005395120853510357261373640343675347141048360175464883004078464167452167371904831096767113443494819262681110739948250607394950735031690197318521195526356325843390998224986240670310768318446607291248747540316179699411397387765899868554170318847788675929026070043212666179192235209382278788809886335991160819235355570464634911320859189796132791319756490976000139962344455350143464268604644958624769094347048293294140411146540923988344435159133201077394411184074107684981066347241048239358274019449356651610884631256785297769734684303061462418035852933159734583038455410337010916767763742762102137013548544509263071901147318485749233181672072137279355679528443925481560913728128406333039373562420016045664557414588166052166608738748047243391212955877763906969037078828527753894052460758496231574369171131761347838827194168606625721036851321566478001476752310393578606896111259960281839309548709059073861351914591819510297327875571049729011487171897180046961697770017913919613791417162707018958469214343696762927459109940060084983568425201915593703701011049747339493877885989417433031785348707603221982970579751191440510994235883034546353492349826883624043327267415540301619505680654180939409982020609994140216890900708213307230896621197755306659188141191577836272927461561857103721724710095214236964830864102592887457999322374955191221951903424452307535133806856807354464995127203174487195403976107308060269906258076020292731455252078079914184290638844373499681458273372072663917670201183004648190002413083508846584152148991276106513741539435657211390328574918769094413702090517031487773461652879848235338297260136110984514841823808120540996125274580881099486972216128524897425555516076371675054896173016809613803811914361143992106380050832140987604599309324851025168294467260666138151745712559754953580239983146982203613380828499356705575524712902745397762140493182014658008021566536067765508783804304134310591804606800834591136640834887408005741272586704792258319127415739080914383138456424150940849133918096840251163991936853225557338966953749026620923261318855891580832455571948453875628786128859004106006073746501402627824027346962528217174941582331749239683530136178653673760642166778137739951006589528877427662636841830680190804609849809469763667335662282915132352788806157768278159588669180238940333076441912403412022316368577860357276941541778826435238131905028087018575047046312933353757285386605888904583111450773942935201994321971171642235005644042979892081594307167019857469273848653833436145794634175922573898588001698014757420542995801242958105456510831046297282937584161162532562516572498078492099897990620035936509934721582965174135798491047111660791587436986541222348341887722929446335178653856731962559852026072947674072616767145573649812105677716893484917660771705277187601199908144113058645577910525684304811440261938402322470939249802933550731845890355397133088446174107959162511714864874468611247605428673436709046678468670274091881014249711149657817724279347070216688295610877794405048437528443375108828264771978540006509704033021862556147332117771174413350281608840351781452541964320309576018694649088681545285621346988355444560249556668436602922195124830910605377201980218310103270417838665447181260397190688462370857518080035327047185659499476124248110999288679158969049563947624608424065930948621507690314987020673533848349550836366017848771060809804269247132410009464014373603265645184566792456669551001502298330798496079949882497061723674493612262229617908143114146609412341593593095854079139087208322733549572080757165171876599449856937956238755516175754380917805280294642004472153962807463602113294255916002570735628126387331060058910652457080244749375431841494014821199962764531068006631183823761639663180931444671298615527598201451410275600689297502463040173514891945763607893528555053173314164570504996443890936308438744847839616840518452732884032345202470568516465716477139323775517294795126132398229602394548579754586517458787713318138752959809412174227300352296508089177705068259248822322154938048371454781647213976820963320508305647920482085920475499857320388876391601995240918938945576768749730856955958010659526503036266159750662225084067428898265907510637563569968211510949669744580547288693631020367823250182323708459790111548472087618212477813266330412076216587312970811230758159821248639807212407868878114501655825136178903070860870198975889807456643955157415363193191981070575336633738038272152798849350397480015890519420879711308051233933221903466249917169150948541401871060354603794643379005890957721180804465743962806186717861017156740967662080295766577051291209907944304632892947306159510430902221439371849560634056189342513057268291465783293340524635028929175470872564842600349629611654138230077313327298305001602567240141851520418907011542885799208121984493156999059182011819733500126187728036812481995877070207532406361259313438595542547781961142935163561223496661522614735399674051584998603552953329245752388810136202347624669055816438967863097627365504724348643071218494373485300606387644566272186661701238127715621379746149861328744117714552444708997144522885662942440230184791205478498574521634696448973892062401943518310088283480249249085403077863875165911302873958787098100772718271874529013972836614842142871705531796543076504534324600536361472618180969976933486264077435199928686323835088756683595097265574815431940195576850437248001020413749831872259677387154958399718444907279141965845930083942637020875635398216962055324803212267498911402678528599673405242031091797899905718821949391320753431707980023736590985375520238911643467185582906853711897952626234492483392496342449714656846591248918556629589329909035239233333647435203707701010843880032907598342170185542283861617210417603011645918780539367447472059985023582891833692922337323999480437108419659473162654825748099482509991833006976569367159689364493348864744213500840700660883597235039532340179582557036016936990988671132109798897070517280755855191269930673099250704070245568507786790694766126298082251633136399521170984528092630375922426742575599892892783704744452189363203489415521044597261883800300677617931381399162058062701651024458869247649246891924612125310275731390840470007143561362316992371694848132554200914530410371354532966206392105479824392125172540132314902740585892063217589494345489068463993137570910346332714153162232805522972979538018801628590735729554162788676498274186164218789885741071649069191851162815285486794173638906653885764229158342500673612453849160674137340173572779956341043326883569507814931378007362354180070619180267328551191942676091221035987469241172837493126163395001239599240508454375698507957046222664619000103500490183034153545842833764378111988556318777792537201166718539541835984438305203762819440761594106820716970302285152250573126093046898423433152732131361216582808075212631547730604423774753505952287174402666389148817173086436111389069420279088143119448799417154042103412190847094080254023932942945493878640230512927119097513536000921971105412096683111516328705423028470073120658032626417116165957613272351566662536672718998534199895236884830999302757419916463841427077988708874229277053891227172486322028898425125287217826030500994510824783572905691988555467886079462805371227042466543192145281760741482403827835829719301017888345674167811398954750448339314689630763396657226727043393216745421824557062524797219978668542798977992339579057581890622525473582205236424850783407110144980478726691990186438822932305382318559732869780922253529591017341407334884761005564018242392192695062083183814546983923664613639891012102177095976704908305081854704194664371312299692358895384930136356576186106062228705599423371631021278457446463989738188566746260879482018647487672727222062676465338099801966883680994159075776852639865146253336312450536402610569605513183813174261184420189088853196356986962795036738424313011331753305329802016688817481342988681585577810343231753064784983210629718425184385534427620128234570716988530518326179641178579608888150329602290705614476220915094739035946646916235396809201394578175891088931992112260073928149169481615273842736264298098234063200244024495894456129167049508235812487391799648641133480324757775219708932772262349486015046652681439877051615317026696929704928316285504212898146706195331970269507214378230476875280287354126166391708245925170010714180854800636923259462019002278087409859771921805158532147392653251559035410209284665925299914353791825314545290598415817637058927906909896911164381187809435371521332261443625314490127454772695739393481546916311624928873574718824071503995009446731954316193855485207665738825139639163576723151005556037263394867208207808653734942440115799667507360711159351331959197120948964717553024531364770942094635696982226673775209945168450643623824211853534887989395673187806606107885440005508276570305587448541805778891719207881423351138662929667179643468760077047999537883387870348718021842437342112273940255717690819603092018240188427057046092622564178375265263358324240661253311529423457965569502506810018310900411245379015332966156970522379210325706937051090830789479999004999395322153622748476603613677697978567386584670936679588583788795625946464891376652199588286933801836011932368578558558195556042156250883650203322024513762158204618106705195330653060606501054887167245377942831338871631395596905832083416898476065607118347136218123246227258841990286142087284956879639325464285343075301105285713829643709990356948885285190402956047346131138263878897551788560424998748316382804046848618938189590542039889872650697620201995548412650005394428203930127481638158530396439925470201672759328574366661644110962566337305409219519675148328734808957477775278344221091073111351828046036347198185655572957144747682552857863349342858423118749440003229690697758315903858039353521358860079600342097547392296733310649395601812237812854584317605561733861126734780745850676063048229409653041118306671081893031108871728167519579675347188537229309616143204006381322465841111157758358581135018569047815368938137718472814751998350504781297718599084707621974605887423256995828892535041937958260616211842368768511418316068315867994601652057740529423053601780313357263267054790338401257305912339601880137825421927094767337191987287385248057421248921183470876629667207272325650565129333126059505777727542471241648312832982072361750574673870128209575544305968395555686861188397135522084452852640081252027665557677495969626612604565245684086139238265768583384698499778726706555191854468698469478495734622606294219624557085371272776523098955450193037732166649182578154677292005212667143463209637891852323215018976126034373684067194193037746880999296877582441047878123266253181845960453853543839114496775312864260925211537673258866722604042523491087026958099647595805794663973419064010036361904042033113579336542426303561457009011244800890020801478056603710154122328891465722393145076071670643556827437743965789067972687438473076346451677562103098604092717090951280863090297385044527182892749689212106670081648583395537735919136950153162018908887484210798706899114804669270650940762046502772528650728905328548561433160812693005693785417861096969202538865034577183176686885923681488475276498468821949739729707737187188400414323127636504814531122850990020742409255859252926103021067368154347015252348786351643976235860419194129697690405264832347009911154242601273438022089331096686367898694977994001260164227609260823493041180643829138347354679725399262338791582998486459271734059225620749105308531537182911681637219395188700957788181586850464507699343940987433514431626330317247747486897918209239480833143970840673084079589358108966564775859905563769525232653614424780230826811831037735887089240613031336477371011628214614661679404090518615260360092521947218890918107335871964142144478654899528582343947050079830388538860831035719306002771194558021911942899922722353458707566246926177663178855144350218287026685610665003531050216318206017609217984684936863161293727951873078972637353717150256378733579771808184878458866504335824377004147710414934927438457587107159731559439426412570270965125108115548247939403597681188117282472158250109496096625393395380922195591918188552678062149923172763163218339896938075616855911752998450132067129392404144593862398809381240452191484831646210147389182510109096773869066404158973610476436500068077105656718486281496371118832192445663945814491486165500495676982690308911185687986929470513524816091743243015383684707292898982846022237301452655679898627767968091469798378268764311598832109043715611299766521539635464420869197567370005738764978437686287681792497469438427465256316323005551304174227341646455127812784577772457520386543754282825671412885834544435132562054464241011037955464190581168623059644769587054072141985212106734332410756767575818456990693046047522770167005684543969234041711089888993416350585157887353430815520811772071880379104046983069578685473937656433631979786803671873079693924236321448450354776315670255390065423117920153464977929066241508328858395290542637687668968805033317227800185885069736232403894700471897619347344308437443759925034178807972235859134245813144049847701732361694719765715353197754997162785663119046912609182591249890367654176979903623755286526375733763526969344354400473067198868901968147428767790866979688522501636949856730217523132529265375896415171479559538784278499866456302878831962099830494519874396369070682762657485810439112232618794059941554063270131989895703761105323606298674803779153767511583043208498720920280929752649812569163425000522908872646925284666104665392171482080130502298052637836426959733707053922789153510568883938113249757071331029504430346715989448786847116438328050692507766274500122003526203709466023414648998390252588830148678162196775194583167718762757200505439794412459900771152051546199305098386982542846407255540927403132571632640792934183342147090412542533523248021932277075355546795871638358750181593387174236"



    errors = 0
    for i in range(0,len(pistr),1):
        if pi_ref[i]!=pistr[i]:
            errors += 1
            print ("Error at digit %d. Expected: %c Actual: %c" % (i,pi_ref[i],pistr[i]))
    if (errors==0):
        print("PASS - no errors")
    return(errors)



digits     = int(sys.argv[1])
base       = int(sys.argv[2])
tuple_size = int(math.log10(base))
digit_tuples  = digits//tuple_size
columns       = 1+digit_tuples*10*tuple_size//3
format_string = "%%0%dd" % tuple_size
pistring = ""
(maxQ,maxDenom,maxR) = (0,0,0)

r = [2 * base//10 ] * columns ## initialise remainder array
(predigits,k,c, multiplications, divisions) = (0,0,0,0,0)

for digit in range (0,digit_tuples,1):
    i = (1 + digit_tuples*tuple_size*10//3) -1
    q = 0
    while True:
        q += (r[i]*base)
        maxQ = max(q,maxQ)

        denom = (2*i) -1
        r[i]= q % denom
        q //= denom

        i-= 1
        if (i == 0):
            break

        maxQ = max(q,maxQ)
        maxDenom = max(denom,maxDenom)
        maxR = max(r[i],maxR)
        q *= i
        maxQ = max(q,maxQ)

        multiplications += 2
        divisions += 1

    result = c+q //base
    divisions += 1


    if result == base:
        print("\nSingle group correction @ digit_tuple %d" % digit)
        predigits += 1
        result = 0
        if predigits == base:
            print("Alarm - correcting predigit overflows at current digit_tuple=%d" % digit)
            predigits = 0

    if digit >0:
        print( format_string % ( predigits ), end="");
        pistring+= format_string % ( predigits )

    predigits = result
    c = q % base;

print( format_string % ( predigits ), end="");
pistring+=format_string % ( predigits )

print("")
check_pi(pistring)

print ("\nStats\n-----")
print ("max Q           = 0x%08X" % maxQ)
print ("max denominator = 0x%08X" % maxDenom)
print ("max remainder   = 0x%08X" % maxR)
print ("multiplications = %d" % multiplications)
print ("divisions       = %d" % divisions)
