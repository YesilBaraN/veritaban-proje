PGDMP  7                    |            mobilya_satis    17.2    17.2 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            �           1262    16393    mobilya_satis    DATABASE     o   CREATE DATABASE mobilya_satis WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C';
    DROP DATABASE mobilya_satis;
                     postgres    false                       1255    16641    genelkarhesapla()    FUNCTION     p  CREATE FUNCTION public.genelkarhesapla() RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    toplamGelir NUMERIC(10, 2);
    toplamMaliyet NUMERIC(10, 2);
    genelKar NUMERIC(10, 2);
BEGIN
    -- Toplam geliri hesapla (toplam sipariş tutarları)
    SELECT SUM(ToplamTutar) INTO toplamGelir FROM Siparis;

    -- Toplam maliyeti hesapla (siparişlerdeki ürünlerin maliyeti)
    SELECT SUM(su.Miktar * su.BirimFiyat) INTO toplamMaliyet
    FROM SiparisUrun su
    JOIN Siparis s ON su.SiparisID = s.SiparisID;

    -- Genel karı hesapla
    genelKar := toplamGelir - toplamMaliyet;

    RETURN genelKar;
END;
$$;
 (   DROP FUNCTION public.genelkarhesapla();
       public               postgres    false                       1255    16967    guncelle_depo_stok()    FUNCTION     %  CREATE FUNCTION public.guncelle_depo_stok() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Urun tablosunda güncellenen stok miktarına göre UrunDepo tablosunu güncelle
    UPDATE UrunDepo
    SET Miktar = NEW.StokMiktari
    WHERE UrunID = NEW.UrunID;
    RETURN NEW;
END;
$$;
 +   DROP FUNCTION public.guncelle_depo_stok();
       public               postgres    false            �            1255    16653    guncelle_siparis_durumu()    FUNCTION     �  CREATE FUNCTION public.guncelle_siparis_durumu() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Örnek: Sipariş durumu "Tamamlandı" olduğunda, ilgili işlemleri güncelle
    IF NEW.Durum = 'Tamamlandı' THEN
        -- Burada yapılacak işlemler
        -- Örneğin, bir log kaydı eklemek veya başka bir tabloyu güncellemek
        RAISE NOTICE 'Sipariş % tamamlandı.', NEW.SiparisID;
    END IF;

    RETURN NEW;
END;
$$;
 0   DROP FUNCTION public.guncelle_siparis_durumu();
       public               postgres    false            �            1255    16649    guncelle_stok()    FUNCTION     �   CREATE FUNCTION public.guncelle_stok() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE Urun
    SET StokMiktari = StokMiktari - NEW.Miktar
    WHERE UrunID = NEW.UrunID;

    RETURN NEW;
END;
$$;
 &   DROP FUNCTION public.guncelle_stok();
       public               postgres    false            �            1255    16651    guncelle_toplam_tutar()    FUNCTION     �   CREATE FUNCTION public.guncelle_toplam_tutar() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE Siparis
    SET ToplamTutar = ToplamTutar + (NEW.Miktar * NEW.BirimFiyat)
    WHERE SiparisID = NEW.SiparisID;

    RETURN NEW;
END;
$$;
 .   DROP FUNCTION public.guncelle_toplam_tutar();
       public               postgres    false                       1255    16847    haftaliksatisraporu()    FUNCTION     \  CREATE FUNCTION public.haftaliksatisraporu() RETURNS TABLE(siparisid integer, musteriid integer, toplamtutar numeric, siparistarih date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT s.SiparisID, s.MusteriID, s.ToplamTutar, s.SiparisTarih
    FROM Siparis s
    WHERE s.SiparisTarih >= CURRENT_DATE - INTERVAL '7 days';
END;
$$;
 ,   DROP FUNCTION public.haftaliksatisraporu();
       public               postgres    false            �            1255    16647    kontrolstokmiktari()    FUNCTION     �  CREATE FUNCTION public.kontrolstokmiktari() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Eğer yeni miktar 5'in altına düşerse
    IF NEW.Miktar < 5 THEN
        -- Uyarı mesajını göster
        RAISE NOTICE 'Uyarı: UrunID % olan ürünün stok miktarı % olan 5''in altına düştü!',
                     NEW.UrunID, NEW.Miktar;
    END IF;
    
    -- Yeni değeri döndürerek işlemin tamamlanmasını sağlıyoruz
    RETURN NEW;
END;
$$;
 +   DROP FUNCTION public.kontrolstokmiktari();
       public               postgres    false                       1255    16846    populerurunler()    FUNCTION     �  CREATE FUNCTION public.populerurunler() RETURNS TABLE(urunid integer, urunadi character varying, toplamsatis integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT u.UrunID, u.UrunAdi, 
           CAST(SUM(su.Miktar) AS INT) AS ToplamSatis
    FROM Urun u
    JOIN SiparisUrun su ON u.UrunID = su.UrunID
    GROUP BY u.UrunID, u.UrunAdi
    ORDER BY ToplamSatis DESC;
END;
$$;
 '   DROP FUNCTION public.populerurunler();
       public               postgres    false                       1255    16965    siparis_tamamlandi_uyarisi()    FUNCTION       CREATE FUNCTION public.siparis_tamamlandi_uyarisi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.Durum = 'Tamamlandı' THEN
        RAISE NOTICE 'Sipariş % tamamlandı. Toplam tutar: %.', NEW.SiparisID, NEW.ToplamTutar;
    END IF;

    RETURN NEW;
END;
$$;
 3   DROP FUNCTION public.siparis_tamamlandi_uyarisi();
       public               postgres    false                       1255    16845    tummusterileraktifsiparisler()    FUNCTION     �  CREATE FUNCTION public.tummusterileraktifsiparisler() RETURNS TABLE(musteriid integer, adsoyad character varying, siparisid integer, siparistarih date, durum character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT m.MusteriID, m.AdSoyad, s.SiparisID, s.SiparisTarih, s.Durum
    FROM Musteri m
    JOIN Siparis s ON m.MusteriID = s.MusteriID
    WHERE s.Durum = 'Aktif';
END;
$$;
 5   DROP FUNCTION public.tummusterileraktifsiparisler();
       public               postgres    false            �            1259    16566    depo    TABLE     �   CREATE TABLE public.depo (
    depoid integer NOT NULL,
    depoadi character varying(100),
    adres text,
    telefon character varying(15)
);
    DROP TABLE public.depo;
       public         heap r       postgres    false            �            1259    16565    depo_depoid_seq    SEQUENCE     �   CREATE SEQUENCE public.depo_depoid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.depo_depoid_seq;
       public               postgres    false    235            �           0    0    depo_depoid_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.depo_depoid_seq OWNED BY public.depo.depoid;
          public               postgres    false    234            �            1259    16545    dolapvedepolama    TABLE     �   CREATE TABLE public.dolapvedepolama (
    kategoriid integer NOT NULL,
    rafsayisi integer,
    kapaksayisi integer,
    kapakturu character varying(100)
);
 #   DROP TABLE public.dolapvedepolama;
       public         heap r       postgres    false            �            1259    16517 
   islemkaydi    TABLE     �   CREATE TABLE public.islemkaydi (
    islemid integer NOT NULL,
    urunid integer,
    kullaniciid integer,
    islemtarih date,
    islemtipi character varying(50),
    aciklama text
);
    DROP TABLE public.islemkaydi;
       public         heap r       postgres    false            �            1259    16516    islemkaydi_islemid_seq    SEQUENCE     �   CREATE SEQUENCE public.islemkaydi_islemid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.islemkaydi_islemid_seq;
       public               postgres    false    230            �           0    0    islemkaydi_islemid_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.islemkaydi_islemid_seq OWNED BY public.islemkaydi.islemid;
          public               postgres    false    229            �            1259    16451    kategori    TABLE     �   CREATE TABLE public.kategori (
    kategoriid integer NOT NULL,
    kategoriadi character varying(100),
    aciklama text,
    renk character varying(50)
);
    DROP TABLE public.kategori;
       public         heap r       postgres    false            �            1259    16450    kategori_kategoriid_seq    SEQUENCE     �   CREATE SEQUENCE public.kategori_kategoriid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.kategori_kategoriid_seq;
       public               postgres    false    218            �           0    0    kategori_kategoriid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.kategori_kategoriid_seq OWNED BY public.kategori.kategoriid;
          public               postgres    false    217            �            1259    16510 	   kullanici    TABLE     �   CREATE TABLE public.kullanici (
    kullaniciid integer NOT NULL,
    adsoyad character varying(100),
    kullaniciadi character varying(50),
    sifre character varying(100),
    songiristarih date
);
    DROP TABLE public.kullanici;
       public         heap r       postgres    false            �            1259    16509    kullanici_kullaniciid_seq    SEQUENCE     �   CREATE SEQUENCE public.kullanici_kullaniciid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.kullanici_kullaniciid_seq;
       public               postgres    false    228            �           0    0    kullanici_kullaniciid_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.kullanici_kullaniciid_seq OWNED BY public.kullanici.kullaniciid;
          public               postgres    false    227            �            1259    16555    masavesehpa    TABLE     �   CREATE TABLE public.masavesehpa (
    kategoriid integer NOT NULL,
    boyut character varying(50),
    sekil character varying(50),
    katlanabilirmi boolean
);
    DROP TABLE public.masavesehpa;
       public         heap r       postgres    false            �            1259    16472    musteri    TABLE     �   CREATE TABLE public.musteri (
    musteriid integer NOT NULL,
    adsoyad character varying(100),
    telefon character varying(15),
    eposta character varying(100),
    adres text
);
    DROP TABLE public.musteri;
       public         heap r       postgres    false            �            1259    16471    musteri_musteriid_seq    SEQUENCE     �   CREATE SEQUENCE public.musteri_musteriid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.musteri_musteriid_seq;
       public               postgres    false    222            �           0    0    musteri_musteriid_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.musteri_musteriid_seq OWNED BY public.musteri.musteriid;
          public               postgres    false    221            �            1259    16535    oturmagrubu    TABLE     �   CREATE TABLE public.oturmagrubu (
    kategoriid integer NOT NULL,
    kapasite integer,
    yastiksayisi integer,
    dosememalzemesi character varying(100)
);
    DROP TABLE public.oturmagrubu;
       public         heap r       postgres    false            �            1259    16481    siparis    TABLE     �   CREATE TABLE public.siparis (
    siparisid integer NOT NULL,
    musteriid integer,
    siparistarih date,
    toplamtutar numeric(10,2),
    durum character varying(50)
);
    DROP TABLE public.siparis;
       public         heap r       postgres    false            �            1259    16480    siparis_siparisid_seq    SEQUENCE     �   CREATE SEQUENCE public.siparis_siparisid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.siparis_siparisid_seq;
       public               postgres    false    224            �           0    0    siparis_siparisid_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.siparis_siparisid_seq OWNED BY public.siparis.siparisid;
          public               postgres    false    223            �            1259    16493    siparisurun    TABLE     �   CREATE TABLE public.siparisurun (
    siparisurunid integer NOT NULL,
    siparisid integer,
    urunid integer,
    miktar integer,
    birimfiyat numeric(10,2),
    tutar numeric(10,2)
);
    DROP TABLE public.siparisurun;
       public         heap r       postgres    false            �            1259    16492    siparisurun_siparisurunid_seq    SEQUENCE     �   CREATE SEQUENCE public.siparisurun_siparisurunid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.siparisurun_siparisurunid_seq;
       public               postgres    false    226            �           0    0    siparisurun_siparisurunid_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.siparisurun_siparisurunid_seq OWNED BY public.siparisurun.siparisurunid;
          public               postgres    false    225            �            1259    16592 	   tedarikci    TABLE     �   CREATE TABLE public.tedarikci (
    tedarikciid integer NOT NULL,
    firmaadi character varying(100),
    telefon character varying(15),
    eposta character varying(100),
    adres text
);
    DROP TABLE public.tedarikci;
       public         heap r       postgres    false            �            1259    16591    tedarikci_tedarikciid_seq    SEQUENCE     �   CREATE SEQUENCE public.tedarikci_tedarikciid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.tedarikci_tedarikciid_seq;
       public               postgres    false    239            �           0    0    tedarikci_tedarikciid_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.tedarikci_tedarikciid_seq OWNED BY public.tedarikci.tedarikciid;
          public               postgres    false    238            �            1259    16460    urun    TABLE     �   CREATE TABLE public.urun (
    urunid integer NOT NULL,
    kategoriid integer,
    eklenmetarihi date,
    urunadi character varying(200),
    birimfiyat numeric(10,2),
    stokmiktari integer
);
    DROP TABLE public.urun;
       public         heap r       postgres    false            �            1259    16459    urun_urunid_seq    SEQUENCE     �   CREATE SEQUENCE public.urun_urunid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.urun_urunid_seq;
       public               postgres    false    220            �           0    0    urun_urunid_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.urun_urunid_seq OWNED BY public.urun.urunid;
          public               postgres    false    219            �            1259    16575    urundepo    TABLE     �   CREATE TABLE public.urundepo (
    urundepoid integer NOT NULL,
    depoid integer,
    urunid integer,
    miktar integer,
    songuncelleme date
);
    DROP TABLE public.urundepo;
       public         heap r       postgres    false            �            1259    16574    urundepo_urundepoid_seq    SEQUENCE     �   CREATE SEQUENCE public.urundepo_urundepoid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.urundepo_urundepoid_seq;
       public               postgres    false    237            �           0    0    urundepo_urundepoid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.urundepo_urundepoid_seq OWNED BY public.urundepo.urundepoid;
          public               postgres    false    236            �            1259    16618    urungorusleri    TABLE     �   CREATE TABLE public.urungorusleri (
    gorusid integer NOT NULL,
    musteriid integer,
    urunid integer,
    gorus text,
    puan integer,
    gorustarihi date
);
 !   DROP TABLE public.urungorusleri;
       public         heap r       postgres    false            �            1259    16617    urungorusleri_gorusid_seq    SEQUENCE     �   CREATE SEQUENCE public.urungorusleri_gorusid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.urungorusleri_gorusid_seq;
       public               postgres    false    243            �           0    0    urungorusleri_gorusid_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.urungorusleri_gorusid_seq OWNED BY public.urungorusleri.gorusid;
          public               postgres    false    242            �            1259    16601    uruntedarikci    TABLE     �   CREATE TABLE public.uruntedarikci (
    uruntedarikciid integer NOT NULL,
    tedarikciid integer,
    urunid integer,
    tedariktarihi date,
    adet integer,
    tutar numeric(10,2)
);
 !   DROP TABLE public.uruntedarikci;
       public         heap r       postgres    false            �            1259    16600 !   uruntedarikci_uruntedarikciid_seq    SEQUENCE     �   CREATE SEQUENCE public.uruntedarikci_uruntedarikciid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.uruntedarikci_uruntedarikciid_seq;
       public               postgres    false    241            �           0    0 !   uruntedarikci_uruntedarikciid_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.uruntedarikci_uruntedarikciid_seq OWNED BY public.uruntedarikci.uruntedarikciid;
          public               postgres    false    240            �           2604    16569    depo depoid    DEFAULT     j   ALTER TABLE ONLY public.depo ALTER COLUMN depoid SET DEFAULT nextval('public.depo_depoid_seq'::regclass);
 :   ALTER TABLE public.depo ALTER COLUMN depoid DROP DEFAULT;
       public               postgres    false    234    235    235            �           2604    16520    islemkaydi islemid    DEFAULT     x   ALTER TABLE ONLY public.islemkaydi ALTER COLUMN islemid SET DEFAULT nextval('public.islemkaydi_islemid_seq'::regclass);
 A   ALTER TABLE public.islemkaydi ALTER COLUMN islemid DROP DEFAULT;
       public               postgres    false    230    229    230            �           2604    16454    kategori kategoriid    DEFAULT     z   ALTER TABLE ONLY public.kategori ALTER COLUMN kategoriid SET DEFAULT nextval('public.kategori_kategoriid_seq'::regclass);
 B   ALTER TABLE public.kategori ALTER COLUMN kategoriid DROP DEFAULT;
       public               postgres    false    217    218    218            �           2604    16513    kullanici kullaniciid    DEFAULT     ~   ALTER TABLE ONLY public.kullanici ALTER COLUMN kullaniciid SET DEFAULT nextval('public.kullanici_kullaniciid_seq'::regclass);
 D   ALTER TABLE public.kullanici ALTER COLUMN kullaniciid DROP DEFAULT;
       public               postgres    false    228    227    228            �           2604    16475    musteri musteriid    DEFAULT     v   ALTER TABLE ONLY public.musteri ALTER COLUMN musteriid SET DEFAULT nextval('public.musteri_musteriid_seq'::regclass);
 @   ALTER TABLE public.musteri ALTER COLUMN musteriid DROP DEFAULT;
       public               postgres    false    222    221    222            �           2604    16484    siparis siparisid    DEFAULT     v   ALTER TABLE ONLY public.siparis ALTER COLUMN siparisid SET DEFAULT nextval('public.siparis_siparisid_seq'::regclass);
 @   ALTER TABLE public.siparis ALTER COLUMN siparisid DROP DEFAULT;
       public               postgres    false    224    223    224            �           2604    16496    siparisurun siparisurunid    DEFAULT     �   ALTER TABLE ONLY public.siparisurun ALTER COLUMN siparisurunid SET DEFAULT nextval('public.siparisurun_siparisurunid_seq'::regclass);
 H   ALTER TABLE public.siparisurun ALTER COLUMN siparisurunid DROP DEFAULT;
       public               postgres    false    225    226    226            �           2604    16595    tedarikci tedarikciid    DEFAULT     ~   ALTER TABLE ONLY public.tedarikci ALTER COLUMN tedarikciid SET DEFAULT nextval('public.tedarikci_tedarikciid_seq'::regclass);
 D   ALTER TABLE public.tedarikci ALTER COLUMN tedarikciid DROP DEFAULT;
       public               postgres    false    239    238    239            �           2604    16463    urun urunid    DEFAULT     j   ALTER TABLE ONLY public.urun ALTER COLUMN urunid SET DEFAULT nextval('public.urun_urunid_seq'::regclass);
 :   ALTER TABLE public.urun ALTER COLUMN urunid DROP DEFAULT;
       public               postgres    false    220    219    220            �           2604    16578    urundepo urundepoid    DEFAULT     z   ALTER TABLE ONLY public.urundepo ALTER COLUMN urundepoid SET DEFAULT nextval('public.urundepo_urundepoid_seq'::regclass);
 B   ALTER TABLE public.urundepo ALTER COLUMN urundepoid DROP DEFAULT;
       public               postgres    false    237    236    237            �           2604    16621    urungorusleri gorusid    DEFAULT     ~   ALTER TABLE ONLY public.urungorusleri ALTER COLUMN gorusid SET DEFAULT nextval('public.urungorusleri_gorusid_seq'::regclass);
 D   ALTER TABLE public.urungorusleri ALTER COLUMN gorusid DROP DEFAULT;
       public               postgres    false    242    243    243            �           2604    16604    uruntedarikci uruntedarikciid    DEFAULT     �   ALTER TABLE ONLY public.uruntedarikci ALTER COLUMN uruntedarikciid SET DEFAULT nextval('public.uruntedarikci_uruntedarikciid_seq'::regclass);
 L   ALTER TABLE public.uruntedarikci ALTER COLUMN uruntedarikciid DROP DEFAULT;
       public               postgres    false    241    240    241            �          0    16566    depo 
   TABLE DATA           ?   COPY public.depo (depoid, depoadi, adres, telefon) FROM stdin;
    public               postgres    false    235   �       �          0    16545    dolapvedepolama 
   TABLE DATA           X   COPY public.dolapvedepolama (kategoriid, rafsayisi, kapaksayisi, kapakturu) FROM stdin;
    public               postgres    false    232   _�       �          0    16517 
   islemkaydi 
   TABLE DATA           c   COPY public.islemkaydi (islemid, urunid, kullaniciid, islemtarih, islemtipi, aciklama) FROM stdin;
    public               postgres    false    230   ��       u          0    16451    kategori 
   TABLE DATA           K   COPY public.kategori (kategoriid, kategoriadi, aciklama, renk) FROM stdin;
    public               postgres    false    218   ��                 0    16510 	   kullanici 
   TABLE DATA           ]   COPY public.kullanici (kullaniciid, adsoyad, kullaniciadi, sifre, songiristarih) FROM stdin;
    public               postgres    false    228   ��       �          0    16555    masavesehpa 
   TABLE DATA           O   COPY public.masavesehpa (kategoriid, boyut, sekil, katlanabilirmi) FROM stdin;
    public               postgres    false    233   ��       y          0    16472    musteri 
   TABLE DATA           M   COPY public.musteri (musteriid, adsoyad, telefon, eposta, adres) FROM stdin;
    public               postgres    false    222   5�       �          0    16535    oturmagrubu 
   TABLE DATA           Z   COPY public.oturmagrubu (kategoriid, kapasite, yastiksayisi, dosememalzemesi) FROM stdin;
    public               postgres    false    231   ��       {          0    16481    siparis 
   TABLE DATA           Y   COPY public.siparis (siparisid, musteriid, siparistarih, toplamtutar, durum) FROM stdin;
    public               postgres    false    224   ۩       }          0    16493    siparisurun 
   TABLE DATA           b   COPY public.siparisurun (siparisurunid, siparisid, urunid, miktar, birimfiyat, tutar) FROM stdin;
    public               postgres    false    226   i�       �          0    16592 	   tedarikci 
   TABLE DATA           R   COPY public.tedarikci (tedarikciid, firmaadi, telefon, eposta, adres) FROM stdin;
    public               postgres    false    239   ��       w          0    16460    urun 
   TABLE DATA           c   COPY public.urun (urunid, kategoriid, eklenmetarihi, urunadi, birimfiyat, stokmiktari) FROM stdin;
    public               postgres    false    220   1�       �          0    16575    urundepo 
   TABLE DATA           U   COPY public.urundepo (urundepoid, depoid, urunid, miktar, songuncelleme) FROM stdin;
    public               postgres    false    237   ��       �          0    16618    urungorusleri 
   TABLE DATA           ]   COPY public.urungorusleri (gorusid, musteriid, urunid, gorus, puan, gorustarihi) FROM stdin;
    public               postgres    false    243   �       �          0    16601    uruntedarikci 
   TABLE DATA           i   COPY public.uruntedarikci (uruntedarikciid, tedarikciid, urunid, tedariktarihi, adet, tutar) FROM stdin;
    public               postgres    false    241   f�       �           0    0    depo_depoid_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.depo_depoid_seq', 6, true);
          public               postgres    false    234            �           0    0    islemkaydi_islemid_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.islemkaydi_islemid_seq', 19, true);
          public               postgres    false    229            �           0    0    kategori_kategoriid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.kategori_kategoriid_seq', 19, true);
          public               postgres    false    217            �           0    0    kullanici_kullaniciid_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.kullanici_kullaniciid_seq', 7, true);
          public               postgres    false    227            �           0    0    musteri_musteriid_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.musteri_musteriid_seq', 10, true);
          public               postgres    false    221            �           0    0    siparis_siparisid_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.siparis_siparisid_seq', 24, true);
          public               postgres    false    223            �           0    0    siparisurun_siparisurunid_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.siparisurun_siparisurunid_seq', 19, true);
          public               postgres    false    225            �           0    0    tedarikci_tedarikciid_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.tedarikci_tedarikciid_seq', 1, true);
          public               postgres    false    238            �           0    0    urun_urunid_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.urun_urunid_seq', 33, true);
          public               postgres    false    219            �           0    0    urundepo_urundepoid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.urundepo_urundepoid_seq', 21, true);
          public               postgres    false    236            �           0    0    urungorusleri_gorusid_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.urungorusleri_gorusid_seq', 13, true);
          public               postgres    false    242            �           0    0 !   uruntedarikci_uruntedarikciid_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.uruntedarikci_uruntedarikciid_seq', 1, true);
          public               postgres    false    240            �           2606    16573    depo depo_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.depo
    ADD CONSTRAINT depo_pkey PRIMARY KEY (depoid);
 8   ALTER TABLE ONLY public.depo DROP CONSTRAINT depo_pkey;
       public                 postgres    false    235            �           2606    16549 $   dolapvedepolama dolapvedepolama_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.dolapvedepolama
    ADD CONSTRAINT dolapvedepolama_pkey PRIMARY KEY (kategoriid);
 N   ALTER TABLE ONLY public.dolapvedepolama DROP CONSTRAINT dolapvedepolama_pkey;
       public                 postgres    false    232            �           2606    16524    islemkaydi islemkaydi_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.islemkaydi
    ADD CONSTRAINT islemkaydi_pkey PRIMARY KEY (islemid);
 D   ALTER TABLE ONLY public.islemkaydi DROP CONSTRAINT islemkaydi_pkey;
       public                 postgres    false    230            �           2606    16458    kategori kategori_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.kategori
    ADD CONSTRAINT kategori_pkey PRIMARY KEY (kategoriid);
 @   ALTER TABLE ONLY public.kategori DROP CONSTRAINT kategori_pkey;
       public                 postgres    false    218            �           2606    16515    kullanici kullanici_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.kullanici
    ADD CONSTRAINT kullanici_pkey PRIMARY KEY (kullaniciid);
 B   ALTER TABLE ONLY public.kullanici DROP CONSTRAINT kullanici_pkey;
       public                 postgres    false    228            �           2606    16559    masavesehpa masavesehpa_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.masavesehpa
    ADD CONSTRAINT masavesehpa_pkey PRIMARY KEY (kategoriid);
 F   ALTER TABLE ONLY public.masavesehpa DROP CONSTRAINT masavesehpa_pkey;
       public                 postgres    false    233            �           2606    16479    musteri musteri_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.musteri
    ADD CONSTRAINT musteri_pkey PRIMARY KEY (musteriid);
 >   ALTER TABLE ONLY public.musteri DROP CONSTRAINT musteri_pkey;
       public                 postgres    false    222            �           2606    16539    oturmagrubu oturmagrubu_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.oturmagrubu
    ADD CONSTRAINT oturmagrubu_pkey PRIMARY KEY (kategoriid);
 F   ALTER TABLE ONLY public.oturmagrubu DROP CONSTRAINT oturmagrubu_pkey;
       public                 postgres    false    231            �           2606    16486    siparis siparis_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.siparis
    ADD CONSTRAINT siparis_pkey PRIMARY KEY (siparisid);
 >   ALTER TABLE ONLY public.siparis DROP CONSTRAINT siparis_pkey;
       public                 postgres    false    224            �           2606    16498    siparisurun siparisurun_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.siparisurun
    ADD CONSTRAINT siparisurun_pkey PRIMARY KEY (siparisurunid);
 F   ALTER TABLE ONLY public.siparisurun DROP CONSTRAINT siparisurun_pkey;
       public                 postgres    false    226            �           2606    16599    tedarikci tedarikci_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.tedarikci
    ADD CONSTRAINT tedarikci_pkey PRIMARY KEY (tedarikciid);
 B   ALTER TABLE ONLY public.tedarikci DROP CONSTRAINT tedarikci_pkey;
       public                 postgres    false    239            �           2606    16465    urun urun_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.urun
    ADD CONSTRAINT urun_pkey PRIMARY KEY (urunid);
 8   ALTER TABLE ONLY public.urun DROP CONSTRAINT urun_pkey;
       public                 postgres    false    220            �           2606    16580    urundepo urundepo_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.urundepo
    ADD CONSTRAINT urundepo_pkey PRIMARY KEY (urundepoid);
 @   ALTER TABLE ONLY public.urundepo DROP CONSTRAINT urundepo_pkey;
       public                 postgres    false    237            �           2606    16625     urungorusleri urungorusleri_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.urungorusleri
    ADD CONSTRAINT urungorusleri_pkey PRIMARY KEY (gorusid);
 J   ALTER TABLE ONLY public.urungorusleri DROP CONSTRAINT urungorusleri_pkey;
       public                 postgres    false    243            �           2606    16606     uruntedarikci uruntedarikci_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.uruntedarikci
    ADD CONSTRAINT uruntedarikci_pkey PRIMARY KEY (uruntedarikciid);
 J   ALTER TABLE ONLY public.uruntedarikci DROP CONSTRAINT uruntedarikci_pkey;
       public                 postgres    false    241            �           2620    16968    urun depo_stok_guncelle    TRIGGER     y   CREATE TRIGGER depo_stok_guncelle AFTER UPDATE ON public.urun FOR EACH ROW EXECUTE FUNCTION public.guncelle_depo_stok();
 0   DROP TRIGGER depo_stok_guncelle ON public.urun;
       public               postgres    false    220    264            �           2620    16654    siparis siparis_durumu_guncelle    TRIGGER     �   CREATE TRIGGER siparis_durumu_guncelle AFTER UPDATE ON public.siparis FOR EACH ROW EXECUTE FUNCTION public.guncelle_siparis_durumu();
 8   DROP TRIGGER siparis_durumu_guncelle ON public.siparis;
       public               postgres    false    224    247            �           2620    16966    siparis siparis_tamamlandi    TRIGGER     �   CREATE TRIGGER siparis_tamamlandi AFTER UPDATE ON public.siparis FOR EACH ROW WHEN (((new.durum)::text = 'Tamamlandı'::text)) EXECUTE FUNCTION public.siparis_tamamlandi_uyarisi();
 3   DROP TRIGGER siparis_tamamlandi ON public.siparis;
       public               postgres    false    263    224    224            �           2620    16650    siparisurun stok_guncelle    TRIGGER     v   CREATE TRIGGER stok_guncelle AFTER INSERT ON public.siparisurun FOR EACH ROW EXECUTE FUNCTION public.guncelle_stok();
 2   DROP TRIGGER stok_guncelle ON public.siparisurun;
       public               postgres    false    245    226            �           2620    16652 !   siparisurun toplam_tutar_guncelle    TRIGGER     �   CREATE TRIGGER toplam_tutar_guncelle AFTER INSERT ON public.siparisurun FOR EACH ROW EXECUTE FUNCTION public.guncelle_toplam_tutar();
 :   DROP TRIGGER toplam_tutar_guncelle ON public.siparisurun;
       public               postgres    false    246    226            �           2620    16648 #   urundepo trigger_kontrolstokmiktari    TRIGGER     �   CREATE TRIGGER trigger_kontrolstokmiktari AFTER UPDATE ON public.urundepo FOR EACH ROW WHEN ((new.miktar < 5)) EXECUTE FUNCTION public.kontrolstokmiktari();
 <   DROP TRIGGER trigger_kontrolstokmiktari ON public.urundepo;
       public               postgres    false    244    237    237            �           2606    16940 /   dolapvedepolama dolapvedepolama_kategoriid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dolapvedepolama
    ADD CONSTRAINT dolapvedepolama_kategoriid_fkey FOREIGN KEY (kategoriid) REFERENCES public.kategori(kategoriid);
 Y   ALTER TABLE ONLY public.dolapvedepolama DROP CONSTRAINT dolapvedepolama_kategoriid_fkey;
       public               postgres    false    218    232    4785            �           2606    16960 &   islemkaydi islemkaydi_kullaniciid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.islemkaydi
    ADD CONSTRAINT islemkaydi_kullaniciid_fkey FOREIGN KEY (kullaniciid) REFERENCES public.kullanici(kullaniciid);
 P   ALTER TABLE ONLY public.islemkaydi DROP CONSTRAINT islemkaydi_kullaniciid_fkey;
       public               postgres    false    230    228    4795            �           2606    16955 !   islemkaydi islemkaydi_urunid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.islemkaydi
    ADD CONSTRAINT islemkaydi_urunid_fkey FOREIGN KEY (urunid) REFERENCES public.urun(urunid);
 K   ALTER TABLE ONLY public.islemkaydi DROP CONSTRAINT islemkaydi_urunid_fkey;
       public               postgres    false    230    220    4787            �           2606    16945 '   masavesehpa masavesehpa_kategoriid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.masavesehpa
    ADD CONSTRAINT masavesehpa_kategoriid_fkey FOREIGN KEY (kategoriid) REFERENCES public.kategori(kategoriid);
 Q   ALTER TABLE ONLY public.masavesehpa DROP CONSTRAINT masavesehpa_kategoriid_fkey;
       public               postgres    false    218    4785    233            �           2606    16935 '   oturmagrubu oturmagrubu_kategoriid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.oturmagrubu
    ADD CONSTRAINT oturmagrubu_kategoriid_fkey FOREIGN KEY (kategoriid) REFERENCES public.kategori(kategoriid);
 Q   ALTER TABLE ONLY public.oturmagrubu DROP CONSTRAINT oturmagrubu_kategoriid_fkey;
       public               postgres    false    231    218    4785            �           2606    16950    siparis siparis_musteriid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.siparis
    ADD CONSTRAINT siparis_musteriid_fkey FOREIGN KEY (musteriid) REFERENCES public.musteri(musteriid);
 H   ALTER TABLE ONLY public.siparis DROP CONSTRAINT siparis_musteriid_fkey;
       public               postgres    false    222    4789    224            �           2606    16910 &   siparisurun siparisurun_siparisid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.siparisurun
    ADD CONSTRAINT siparisurun_siparisid_fkey FOREIGN KEY (siparisid) REFERENCES public.siparis(siparisid);
 P   ALTER TABLE ONLY public.siparisurun DROP CONSTRAINT siparisurun_siparisid_fkey;
       public               postgres    false    226    4791    224            �           2606    16915 #   siparisurun siparisurun_urunid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.siparisurun
    ADD CONSTRAINT siparisurun_urunid_fkey FOREIGN KEY (urunid) REFERENCES public.urun(urunid);
 M   ALTER TABLE ONLY public.siparisurun DROP CONSTRAINT siparisurun_urunid_fkey;
       public               postgres    false    226    220    4787            �           2606    16930    urun urun_kategoriid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.urun
    ADD CONSTRAINT urun_kategoriid_fkey FOREIGN KEY (kategoriid) REFERENCES public.kategori(kategoriid);
 C   ALTER TABLE ONLY public.urun DROP CONSTRAINT urun_kategoriid_fkey;
       public               postgres    false    220    4785    218            �           2606    16890    urundepo urundepo_depoid_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.urundepo
    ADD CONSTRAINT urundepo_depoid_fkey FOREIGN KEY (depoid) REFERENCES public.depo(depoid);
 G   ALTER TABLE ONLY public.urundepo DROP CONSTRAINT urundepo_depoid_fkey;
       public               postgres    false    4805    235    237            �           2606    16895    urundepo urundepo_urunid_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.urundepo
    ADD CONSTRAINT urundepo_urunid_fkey FOREIGN KEY (urunid) REFERENCES public.urun(urunid);
 G   ALTER TABLE ONLY public.urundepo DROP CONSTRAINT urundepo_urunid_fkey;
       public               postgres    false    220    4787    237            �           2606    16920 *   urungorusleri urungorusleri_musteriid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.urungorusleri
    ADD CONSTRAINT urungorusleri_musteriid_fkey FOREIGN KEY (musteriid) REFERENCES public.musteri(musteriid);
 T   ALTER TABLE ONLY public.urungorusleri DROP CONSTRAINT urungorusleri_musteriid_fkey;
       public               postgres    false    243    222    4789            �           2606    16925 '   urungorusleri urungorusleri_urunid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.urungorusleri
    ADD CONSTRAINT urungorusleri_urunid_fkey FOREIGN KEY (urunid) REFERENCES public.urun(urunid);
 Q   ALTER TABLE ONLY public.urungorusleri DROP CONSTRAINT urungorusleri_urunid_fkey;
       public               postgres    false    4787    243    220            �           2606    16900 ,   uruntedarikci uruntedarikci_tedarikciid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.uruntedarikci
    ADD CONSTRAINT uruntedarikci_tedarikciid_fkey FOREIGN KEY (tedarikciid) REFERENCES public.tedarikci(tedarikciid);
 V   ALTER TABLE ONLY public.uruntedarikci DROP CONSTRAINT uruntedarikci_tedarikciid_fkey;
       public               postgres    false    4809    239    241            �           2606    16905 '   uruntedarikci uruntedarikci_urunid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.uruntedarikci
    ADD CONSTRAINT uruntedarikci_urunid_fkey FOREIGN KEY (urunid) REFERENCES public.urun(urunid);
 Q   ALTER TABLE ONLY public.uruntedarikci DROP CONSTRAINT uruntedarikci_urunid_fkey;
       public               postgres    false    220    4787    241            �   G   x�3�t��N,JTpI-ȇ�uB�)�άL�40642426153�2�<���$1/�4��E�`������ 06      �      x�3�4�4�>��(���{�b���� Uq~      �   Z   x�3�4B##]C]C��Ē#������))�V(I�>�1��F�b�8�U�XpdcNʑ�\F�`�l����X�.�/��+F��� e?.�      u   �   x�-��
�0E痯x_ �_ J)����HC_��6�;:gqrK�_��t�=���v�N��z��p7�=����Q3����ľ�H$�eg	�g��:�2��d�E(8t�LV�2Lvu*iK��g�!���o��ޏ��,���=��F�)?�         O   x�3��M��M-Qp�����9����R��9��Ltu̹�8�R+�R�+9��l�bS3�b�=... X��      �   (   x�3�420�040PH��t��N9���$=5���+F��� �	      y   l   x�3�t��M-Q�<�1'7������������̜3$�Z��[�������阗�X���rxOQvfe*��kNf��KjnfP��Lo*PE��%�yI�9H�c���� �+      �      x�3�4���NL�LK����� #��      {   ~   x�U��1D��*h�����t@Hb� Y�$�=P��c���
���`[�` �p���6�\j.jb?*��!�Tj��t�χ��؄��r/g%??s�).�����Ō�|�|��u�G���� �Y/�      }   4   x�3�4�@S=8�ˈ9-L!P�����(k
�0�J��qqq �?C      �   t   x�3���O�̩LTp�;:O�����������Ę33/-�!"�����阗�X���rxOQvfe*��KjA��N#C#�N#C���������d3�l(.I�K*�A2&F��� �-�      w   o   x�3�4�4202�50�50�L�M�V�M,N,>������@���Ӝˈ��̈�=�(��Ƣ�N�K.c�j���9j9��sJJ�B��l�ZhT	Vjb����� �;&�      �   &   x�3�4BcN##]C]C#.CN41C����� �|�      �   p   x�3�4B�����l����#s�lT8�<?[�(1#�D�,U���#��8M9��Ltu,��8A�=�(��Ƣ����������Ksr�l<:?��F=N�&K�=... �&�      �   4   x�5��	 0���.ʝ�t��?G�`�	DP��rʹ B�M���έN�̽afRe
:     