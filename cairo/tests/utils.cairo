%lang starknet

func fillInputSingleBlock():
    %{
        #adds block 1 from the bitcoin TESTNET
        program_input = {
            "Blocks": [[16777216, 1128890327, 4163278193, 150250255, 3654206382, 3128530720, 2229866157, 32125705, 0, 3133714682, 2457602760, 591562723, 1012888787, 2369079328, 3796326061, 1889366072, 4234097136, 552028493, 4294901789, 65320562]],
            "firstEpochBlock": [16777216, 0, 0, 0, 0, 0, 0, 0, 0, 1000599037, 2054886066, 2059873342, 1735823201, 2143820739, 2290766130, 983546026, 1260281418, 3672459597, 4294901789, 447000088],
            "blockNrThisEpoch": 1
        }
    %}
    return ()
end

func fillInputMultipleBlocks():
    %{
        # adds first 11 blocks from the bitcoin MAINNET
        program_input = {
            "Blocks": [[16777216,1877117962,3069293426,3248923206,2925786959,2468250469,3780774044,1758861568,0,2552254973,508274500,3149817870,535696487,2074190787,1410070449,3451258600,1461927438,1639736905,4294901789,31679129],[16777216,1214311192,3206223392,3816723600,4236919413,339832791,1364831110,1754176131,0,3590179924,505798172,2052775405,4064827576,3144047775,921662542,3828101472,583602075,2965136969,4294901789,148028769],[16777216,3185416652,4255358369,2970144282,1567622029,177634220,3062590307,106914410,0,1157001762,1620105309,3114922747,4267642774,162760623,2078652411,3080812156,2199690905,1572759113,4294901789,98626925],[16777216,1229211285,1655577644,1960420661,3758845758,1090501332,4076708745,1426175362,0,2047273624,3443571246,847783467,677612780,1396162885,1789877997,3370771874,252062687,2361484873,4294901789,738123945],[16777216,2232699524,1217308813,572296150,3227113993,243857570,3382087918,1440463438,0,3776727294,3453609765,281707760,590810266,952078764,1554941953,2616104146,1160270435,1153656393,4294901789,486794359],[16777216,4231263638,4163018913,2501901759,713653001,1446423943,386383709,828535451,0,933100438,2783612033,1880007852,1805102746,2467476180,807020888,244469478,1981424928,2915329609,4294901789,412896407],[16777216,2373423068,362992635,1991709226,995459774,2767331162,208221495,3886035248,0,1063731205,272319225,2216074365,8614038,2123469322,1784505597,1361588085,3161695882,4056311369,4294901789,967154822],[16777216,1150601423,1096072652,119590218,1507445170,2246357318,3562997277,728536689,0,3817168600,2254461805,1251595770,787671472,2976179773,4089713515,3958558938,3237083046,1741186633,4294901789,474699366],[16777216,3322797809,3076623522,881477352,1756349038,1056729122,1819847239,4165504064,0,3382158821,1846558978,4196441194,2234374406,1621232429,2620728355,3989710213,2144155396,2143970889,4294901789,675303251],[16777216,84412508,1204585630,3087968517,3430416547,3194441724,1462123762,281386381,0,288072053,2715831060,3130949285,4150965824,2952720222,3380704172,2543429714,4198084051,550331977,4294901789,506324325],[16777216,3910523300,2028187123,409733062,438444683,285050847,876384888,785122604,0,1845901116,2162047348,115096857,3373101522,805670184,691410154,1490462079,2405249784,3100534345,4294901789,389548024]],
            "firstEpochBlock": [16777216,0,0,0,0,0,0,0,0,1000599037,2054886066,2059873342,1735823201,2143820739,2290766130,983546026,1260281418,699096905,4294901789,497822588],
            "blockNrThisEpoch": 1
        }
    %}
    return ()
end